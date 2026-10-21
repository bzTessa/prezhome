import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_inventory_item_screen.dart';
import 'models/inventory_item.dart';
import 'models/shopping_list_item.dart';
import 'scan_barcode_screen.dart';
import 'services/home_supermarkets.dart';
import 'services/offline_provider.dart';
import 'services/offline_repository.dart';
import 'services/pantry_usage.dart';
import 'services/product_photo_resolver.dart';
import 'services/proactive_suggestions_service.dart';
import 'services/taper_sync.dart';
import 'theme/app_theme.dart';
import 'widgets/empty_state.dart';
import 'widgets/list_skeleton.dart';
import 'utils/offline_actions.dart';
import 'widgets/animations/swipe_action.dart';
import 'widgets/food_image.dart';
import 'widgets/product_photo_menu.dart';
import 'widgets/shopping/shopping_parts.dart';
import 'widgets/tactile_button.dart';
import 'utils/shopping_display.dart';
import 'widgets/pending_sync_indicator.dart';
import 'utils/friendly_error.dart';
import 'utils/kitchen_zones.dart';
import 'widgets/kitchen/kitchen_zones_grid.dart';
import 'discover_recipes_screen.dart';

class InventoryScreen extends StatefulWidget {
  final bool embedded;
  const InventoryScreen({super.key, this.embedded = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Repositorio offline-first COMPARTIDO del inventario (singleton): la caché y
  // la cola se comparten con la instancia gemela (embebida/ruta) y con el
  // _addToPantry de la lista de la compra.
  final OfflineRepository _repo = OfflineProvider.instance.inventory;

  late Future<List<InventoryItem>> _itemsFuture;

  // Nº de cambios pendientes de sincronizar, para el indicador discreto.
  int _pendingCount = 0;

  // Contador monótono para encolar/identificar ops de forma estable.
  int _opSeq = 0;

  // Zona que se ve: filterKey de [KitchenZone], 'revisar' (lo que caduca, de
  // todas las zonas) o null hasta que se elige (primera zona con productos).
  String? _sectionFilter;

  StreamSubscription<void>? _changesSub;

  @override
  void initState() {
    super.initState();
    // OFFLINE-FIRST: pintamos AL INSTANTE desde la caché local y, en paralelo,
    // refrescamos desde Supabase (que, al llegar, reemplaza la lista).
    _itemsFuture = _loadFromCache();
    _refreshFromRemote();
    _usePlanIngredients();
    // Lo comprado en la lista entra por el mismo repositorio: repintamos al
    // momento aunque esta pestaña ya estuviera abierta.
    _changesSub = _repo.changes.listen((_) async {
      final items = _rowsToItems(await _repo.readCached());
      if (!mounted) return;
      setState(() {
        _itemsFuture = Future.value(items);
        _pendingCount = _repo.pendingCount;
      });
    });
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    super.dispose();
  }

  /// Quita de la despensa lo que se ha usado en las comidas del plan que ya
  /// han pasado y lo avisa.
  Future<void> _usePlanIngredients() async {
    final cooked = await PantryUsage.syncPlan(Supabase.instance.client);
    if (cooked.isEmpty || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cooked.length == 1
              ? 'Quitado lo que usaste en ${cooked.first}'
              : 'Quitado lo que usaste en ${cooked.length} comidas del plan',
        ),
        persist: false,
        action: SnackBarAction(label: 'Ver', onPressed: _openHistory),
      ),
    );
  }

  /// Siguiente número de secuencia para encolar/identificar ops de forma
  /// estable (monótono mientras viva la pantalla).
  int _nextSeq() => _opSeq++;

  /// Convierte filas crudas (caché o remoto) en modelos, con el MISMO orden que
  /// la consulta original: por fecha de creación descendente (lo más nuevo
  /// arriba). created_at no está en el modelo, así que ordenamos sobre la fila
  /// cruda; las filas sin fecha quedan al final de forma estable.
  List<InventoryItem> _rowsToItems(List<Map<String, dynamic>> rows) {
    final sorted = List<Map<String, dynamic>>.from(rows);
    sorted.sort((a, b) {
      final da = _rowCreatedAt(a);
      final db = _rowCreatedAt(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da); // descendente
    });
    // Filas a medias (sin nombre) no se pintan: serían de un cambio local
    // incompleto.
    return sorted
        .where((r) => (r['name'] ?? '').toString().trim().isNotEmpty)
        .map(InventoryItem.fromMap)
        .toList();
  }

  /// Lee created_at de una fila cruda (ISO-8601 o DateTime). Null si falta.
  DateTime? _rowCreatedAt(Map<String, dynamic> row) {
    final raw = row['created_at'];
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  /// Carga INSTANTÁNEA desde la caché local (último estado + ops pendientes).
  Future<List<InventoryItem>> _loadFromCache() async {
    final rows = await _repo.readCached();
    _pendingCount = _repo.pendingCount;
    return _rowsToItems(rows);
  }

  /// Refresca desde Supabase (fetch + merge con pendientes + guardar caché) e
  /// intenta drenar la cola si hay red. Si falla (sin cobertura) nos quedamos
  /// con la caché. setState con cuerpo de bloque (nunca arrow con Future).
  Future<void> _refreshFromRemote() async {
    try {
      // Antes de leer, que estén los tápers de la cocina en lote al día.
      await TaperSync.sync(Supabase.instance.client);
      final rows = await _repo.refreshFromRemote();
      var items = _rowsToItems(rows);
      if (await _mergeDuplicates(items)) {
        items = _rowsToItems(await _repo.readCached());
      }
      unawaited(_recheckOldPhotos(rows));
      if (!mounted) return;
      final pending = _repo.pendingCount;
      setState(() {
        _itemsFuture = Future.value(items);
        _pendingCount = pending;
      });
    } catch (_) {
      // Sin conexión: conservamos lo pintado desde la caché.
    }
  }

  bool _photosRechecked = false;

  /// Las fotos de OFF a veces eran otro producto (vinagre por vino): se
  /// comprueban y, si no son ese producto, se cambian o se quitan.
  Future<void> _recheckOldPhotos(List<Map<String, dynamic>> rows) async {
    if (_photosRechecked) return;
    _photosRechecked = true;
    final old = [
      for (final r in rows)
        if (isSharablePhoto((r['image_url'] ?? '').toString())) r,
    ];
    if (old.isEmpty) return;
    try {
      final homeId = await _homeId();
      final resolver = ProductPhotoResolver(Supabase.instance.client);
      // Cada cambio repinta solo (OfflineRepository.changes).
      for (final r in old) {
        final id = r['id']?.toString();
        if (id == null || isLocalId(id)) continue;
        final name = r['name'].toString();
        final current = r['image_url'].toString();
        if (await resolver.photoMatches(name, current) != false) continue;
        final url = await resolver.photoFor(
          homeId: homeId,
          name: r['name'].toString(),
        );
        if (url == r['image_url']) continue;
        await _repo.applyLocalWrite(
          buildUpdateOp(
            table: kInventoryTable,
            id: id,
            changes: {'image_url': url},
            nowMillis: DateTime.now().millisecondsSinceEpoch,
            seq: _nextSeq(),
          ),
        );
      }
    } catch (_) {
      // Sin red se revisa la próxima vez.
      _photosRechecked = false;
    }
  }

  /// Une los productos repetidos (p. ej. el mismo jamón comprado tres veces)
  /// en uno solo con la cantidad sumada. Devuelve si cambió algo.
  Future<bool> _mergeDuplicates(List<InventoryItem> items) async {
    final merges = findPantryDuplicates(items);
    for (final m in merges) {
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: m.keep.id,
          changes: {
            'quantity': m.quantity,
            'expiration_date': m.expirationDate
                ?.toIso8601String()
                .split('T')
                .first,
          },
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      for (final id in m.removeIds) {
        await _repo.applyLocalWrite(
          buildDeleteOp(
            table: kInventoryTable,
            id: id,
            nowMillis: DateTime.now().millisecondsSinceEpoch,
            seq: _nextSeq(),
          ),
        );
      }
    }
    return merges.isNotEmpty;
  }

  /// Recarga tras una escritura optimista: repinta al instante desde la caché y
  /// refresca en segundo plano. setState con cuerpo de bloque.
  Future<void> _reload() async {
    final rows = await _repo.readCached();
    final items = _rowsToItems(rows);
    final pending = _repo.pendingCount;
    if (!mounted) return;
    setState(() {
      _itemsFuture = Future.value(items);
      _pendingCount = pending;
    });
    _refreshFromRemote();
  }

  Future<void> _deleteItem(InventoryItem item) async {
    try {
      // Delete OPTIMISTA por el repositorio: desaparece al instante y se envía
      // al drenar. Si el id era local (insert sin sincronizar), la cola colapsa
      // ambas ops y no manda nada al servidor.
      await _repo.applyLocalWrite(
        buildDeleteOp(
          table: kInventoryTable,
          id: item.id,
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, 'No se pudo eliminar')),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  /// Alterna el flag "siempre en casa" (is_staple) de un item para que la
  /// usuaria pueda gestionar sus basicos de un vistazo desde el inventario.
  Future<void> _toggleStaple(InventoryItem item, bool value) async {
    try {
      // UPDATE OPTIMISTA de is_staple vía el repositorio.
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: item.id,
          changes: {'is_staple': value},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '${item.name} ya no aparecerá en la compra.'
                : '${item.name} volverá a aparecer en la compra.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo actualizar')),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Marca un alimento como "agotado": pone su cantidad a 0 (UPDATE optimista
  /// vía la capa offline-first, igual que [_toggleStaple]) y, si además es un
  /// BÁSICO ("siempre en casa"), lo repone automáticamente en la lista de la
  /// compra con el motor predictivo local (FEAT-002), deduplicando por nombre.
  ///
  /// Todas las escrituras pasan por applyLocalWrite (inventario y compra), de
  /// modo que funciona sin conexión: se encolan y la UI repinta al instante.
  /// setState con cuerpo de bloque (nunca arrow con Future).
  Future<void> _markDepleted(InventoryItem item) async {
    // Guardamos la cantidad previa para poder restaurarla con "Deshacer".
    final previousQty = item.quantity;

    // (1) UPDATE OPTIMISTA de la cantidad a 0 vía el repositorio del
    // inventario (mismo patrón exacto que _toggleStaple). Si ESTE paso falla,
    // no se ha escrito nada: el mensaje refleja justo eso.
    try {
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: item.id,
          changes: {'quantity': 0},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(e, 'No se pudo marcar ${item.name} como agotado'),
          ),
          backgroundColor: AppColors.expired,
        ),
      );
      return;
    }

    // (2) Reposición inteligente SOLO para básicos agotados. La regla la
    // decide el servicio puro (isDepletedStaple) para que UI y motor usen el
    // mismo criterio testeado.
    if (!isDepletedStaple(item.isStaple, 0)) {
      if (!mounted) return;
      // No es básico: dejamos la cantidad a 0 sin tocar la compra y avisamos
      // de forma simple.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('He marcado ${item.name} como agotado.')),
      );
      return;
    }

    // La despensa YA se actualizó con éxito; si la reposición falla, el
    // mensaje debe dejar claro que lo que no pudo completarse fue añadirlo a
    // la compra (no confundirlo con el agotado, que sí quedó registrado).
    try {
      await _restockDepletedStaple(item, previousQty: previousQty);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(
              e,
              '${item.name} quedó agotado, pero no pude añadirlo a la compra',
            ),
          ),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Reponer un básico agotado en la lista de la compra: construye el
  /// ShoppingListItem con el motor puro (source 'auto', dedup por nombre contra
  /// la compra cacheada) y, si procede, lo inserta vía la capa offline-first
  /// (mismo patrón que _addToPantry pero en sentido despensa -> compra).
  Future<void> _restockDepletedStaple(
    InventoryItem item, {
    required double previousQty,
  }) async {
    // home_id del hogar: lo tomamos del PROPIO item agotado (item.homeId), que
    // ya viene de la caché offline-first (home_id de su fila), así la
    // reposición no depende de red. Es correcto porque el item pertenece al
    // hogar del usuario y la línea de la compra debe ir a ese mismo hogar. Solo
    // si por algún motivo llegara vacío (dato incompleto) caemos al helper de
    // red _homeId() como último recurso.
    final homeId = item.homeId.isNotEmpty ? item.homeId : await _homeId();

    // Nombres ya presentes en la compra (caché incluye ops pendientes) para
    // deduplicar y no crear líneas repetidas.
    final shoppingRepo = OfflineProvider.instance.shopping;
    final existingRows = await shoppingRepo.readCached();
    final existingNames = existingRows
        .map((m) => (m['name'] ?? '').toString())
        .where((n) => n.isNotEmpty);

    final restock = buildRestockItem(
      homeId: homeId,
      name: item.name,
      itemType: item.itemType,
      category: item.category,
      unit: item.unit,
      imageUrl: item.imageUrl,
      existingShoppingNames: existingNames,
    );

    if (restock == null) {
      // Ya estaba en la compra: nada que insertar, pero confirmamos el agotado.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} ya está en tu lista de la compra.'),
        ),
      );
      return;
    }

    // Insert OPTIMISTA con id temporal local, igual que _addToPantry: se
    // reconstruye el item con el localId antes de cachear (toCacheMap incluye id).
    final now = DateTime.now().millisecondsSinceEpoch;
    final localId = newLocalId(nowMillis: now, seq: _nextSeq());
    final withId = ShoppingListItem(
      id: localId,
      homeId: restock.homeId,
      name: restock.name,
      quantity: restock.quantity,
      unit: restock.unit,
      checked: restock.checked,
      source: restock.source,
      itemType: restock.itemType,
      category: restock.category,
      imageUrl: restock.imageUrl,
    );
    await shoppingRepo.applyLocalWrite(
      buildInsertOp(
        table: kShoppingTable,
        id: localId,
        payload: withId.toCacheMap(),
        nowMillis: now,
        seq: _nextSeq(),
      ),
    );

    if (!mounted) return;
    // SnackBar cozy con acción Deshacer: borra de la compra el item recién
    // creado y restaura la cantidad previa del inventario (ambas por la capa
    // offline-first).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('He añadido ${item.name} a la compra'),
        // Con acción Flutter la deja fija; que se vaya sola.
        persist: false,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => _undoRestock(
            item: item,
            shoppingLocalId: localId,
            previousQty: previousQty,
          ),
        ),
      ),
    );
  }

  /// Revierte una reposición automática: borra de la compra la línea insertada
  /// y restaura la cantidad previa del item en el inventario. Ambas escrituras
  /// pasan por applyLocalWrite. setState con cuerpo de bloque (vía _reload).
  Future<void> _undoRestock({
    required InventoryItem item,
    required String shoppingLocalId,
    required double previousQty,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await OfflineProvider.instance.shopping.applyLocalWrite(
        buildDeleteOp(
          table: kShoppingTable,
          id: shoppingLocalId,
          nowMillis: now,
          seq: _nextSeq(),
        ),
      );
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: item.id,
          changes: {'quantity': previousQty},
          nowMillis: now,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo deshacer')),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Obtiene el home_id del usuario autenticado leyendo su perfil (mismo helper
  /// que _homeId() en shopping_list_screen.dart).
  Future<String> _homeId() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw 'No hay usuario autenticado';
    final profile = await client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .single();
    final homeId = profile['home_id'] as String?;
    if (homeId == null) throw 'El usuario no esta asignado a ningun hogar.';
    return homeId;
  }

  Future<void> _openAddItem() async {
    // La pantalla de alta devuelve el item construido (o null si se cancela);
    // aquí lo aplicamos de forma optimista + encolamos.
    final result = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
    );
    if (result != null) await _applyUpsert(result, editing: false);
  }

  /// Abre el escáner de código de barras. La pantalla de escaneo busca el
  /// producto en Open Food Facts y navega al formulario de alta (precargado o
  /// vacío); el item construido vuelve aquí como resultado y se aplica con el
  /// MISMO camino optimista que el alta manual.
  /// Hoja con las formas de añadir: a mano o escaneando el código de barras.
  Future<void> _openAddOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Añadir a mano'),
              onTap: () => Navigator.of(ctx).pop('manual'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: const Text('Escanear código de barras'),
              onTap: () => Navigator.of(ctx).pop('scan'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'manual') await _openAddItem();
    if (choice == 'scan') await _openScanBarcode();
  }

  Future<void> _openScanBarcode() async {
    final result = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(builder: (_) => const ScanBarcodeScreen()),
    );
    if (result != null) await _applyUpsert(result, editing: false);
  }

  /// Aplica un alta/edición de inventario de forma OPTIMISTA: para un alta
  /// nueva genera un id temporal local e INSERTA; para una edición, UPDATE
  /// sobre el id real. En ambos casos la UI refleja el cambio al instante y la
  /// cola lo envía a Supabase en segundo plano.
  Future<void> _applyUpsert(InventoryItem item, {required bool editing}) async {
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    if (editing && item.id.isNotEmpty) {
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: item.id,
          changes: item.toCacheMap(),
          nowMillis: nowMillis,
          seq: _nextSeq(),
        ),
      );
    } else {
      final localId = newLocalId(nowMillis: nowMillis, seq: _nextSeq());
      final withId = InventoryItem(
        id: localId,
        homeId: item.homeId,
        name: item.name,
        category: item.category,
        itemType: item.itemType,
        quantity: item.quantity,
        unit: item.unit,
        expirationDate: item.expirationDate,
        isStaple: item.isStaple,
        kind: item.kind,
        recipeId: item.recipeId,
        servings: item.servings,
        frozenOn: item.frozenOn,
        bestBefore: item.bestBefore,
        imageUrl: item.imageUrl,
      );
      await _repo.applyLocalWrite(
        buildInsertOp(
          table: kInventoryTable,
          id: localId,
          payload: withId.toCacheMap(),
          nowMillis: nowMillis,
          seq: _nextSeq(),
        ),
      );
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                'Despensa y Nevera',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.cream,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.ink),
            ),
      // Un solo botón: las formas de añadir van en una hoja (antes eran dos
      // botones flotantes apilados que tapaban la lista).
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-inventory',
        onPressed: _openAddOptions,
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.cream,
        tooltip: 'Añadir a la despensa',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: FutureBuilder<List<InventoryItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton();
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                friendlyError(
                  snapshot.error,
                  'No se pudo cargar el inventario',
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return EmptyState(
              image: 'assets/images/vacio_despensa.png',
              title: 'Tu despensa está vacía',
              message:
                  'Añade lo que tienes en casa o tacha la compra y '
                  'llegará solo.',
              actionLabel: 'Añadir producto',
              onAction: _openAddOptions,
            );
          }

          return Column(
            children: [
              // Indicador discreto de "cambios por sincronizar": aparece solo
              // con cola no vacía y desaparece al drenar.
              if (shouldShowPendingIndicator(_pendingCount))
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: PendingSyncIndicator(pendingCount: _pendingCount),
                ),
              Expanded(child: _buildKitchen(items)),
            ],
          );
        },
      ),
    );
  }

  static bool _tracksExpiry(InventoryItem i) =>
      i.itemType == 'comida' && i.category != 'Especias';

  static bool _isUrgent(InventoryItem i) =>
      _tracksExpiry(i) &&
      (i.expiryStatus == ExpiryStatus.caducado ||
          i.expiryStatus == ExpiryStatus.pronto);

  /// Mi cocina: las zonas hacen de pestañas y debajo va SOLO la zona elegida,
  /// en filas compactas. Así nada sale dos veces.
  Widget _buildKitchen(List<InventoryItem> items) {
    final zones = summarizeZones(items);
    final review = _sectionFilter == 'revisar';
    final zone = review
        ? null
        : KitchenZone.byFilterKey(_sectionFilter ?? '') ??
              zones
                  .firstWhere((z) => z.count > 0, orElse: () => zones.first)
                  .zone;
    final shown = items
        .where((i) => review ? _isUrgent(i) : zone!.matches(i))
        .toList();
    final alphabetical =
        zone == KitchenZone.especias ||
        zone == KitchenZone.limpieza ||
        zone == KitchenZone.hogar;
    if (alphabetical) {
      shown.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else {
      // Lo que antes caduca, arriba; lo que no tiene fecha, al final.
      shown.sort((a, b) {
        final da = a.daysUntilExpiry, db = b.daysUntilExpiry;
        if (da == null && db == null) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        112,
      ),
      children: [
        KitchenZonesGrid(
          zones: zones,
          selected: zone,
          onSelect: (z) {
            HapticFeedback.selectionClick();
            setState(() => _sectionFilter = z?.filterKey ?? 'revisar');
          },
          trailing: _cleanupMenu(items, zone),
        ),
        const SizedBox(height: AppSpacing.md),
        // Al revés que el plan: ideas de recetas con lo que ya hay.
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DiscoverRecipesScreen(pantryMode: true),
            ),
          ),
          icon: const Icon(Icons.soup_kitchen_outlined, size: 20),
          label: const Text('¿Qué cocino con esto?'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            backgroundColor: AppColors.wood.withValues(alpha: 0.35),
            foregroundColor: AppColors.ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            review
                ? 'Caducados y a punto de caducar'
                : '${zone!.label} · ${shown.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Aquí no hay nada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted),
            ),
          )
        else
          for (final g in _groups(shown, byExpiry: !alphabetical)) ...[
            if (g.label != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 0, 6),
                child: Text(
                  g.label!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: g.color ?? AppColors.inkMuted,
                  ),
                ),
              ),
            Container(
              decoration: AppTheme.surfaceDecoration(radius: AppRadius.md),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var k = 0; k < g.items.length; k++) ...[
                    if (k > 0)
                      Divider(height: 1, indent: 76, color: AppColors.line),
                    _itemRow(g.items[k], showZone: review),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  /// Parte la lista por cuándo caduca (ya viene ordenada) para verla de un
  /// vistazo: caducado, esta semana, más adelante y sin fecha. Con un solo
  /// grupo no se pone título.
  List<({String? label, Color? color, List<InventoryItem> items})> _groups(
    List<InventoryItem> items, {
    required bool byExpiry,
  }) {
    if (!byExpiry) return [(label: null, color: null, items: items)];
    final buckets = <String, List<InventoryItem>>{};
    for (final i in items) {
      final d = _tracksExpiry(i) ? i.daysUntilExpiry : null;
      final key = switch (d) {
        null => 'Sin fecha',
        < 0 => 'Caducado',
        <= 7 => 'Esta semana',
        _ => 'Más adelante',
      };
      buckets.putIfAbsent(key, () => []).add(i);
    }
    final groups = [
      for (final k in ['Caducado', 'Esta semana', 'Más adelante', 'Sin fecha'])
        if (buckets[k] case final list?)
          (
            label: k,
            color: k == 'Caducado' ? AppColors.expired : null,
            items: list,
          ),
    ];
    return groups.length == 1
        ? [(label: null, color: null, items: items)]
        : groups;
  }

  /// Fila de producto: foto, nombre, cantidad y, si caduca, cuándo.
  Widget _itemRow(InventoryItem item, {required bool showZone}) {
    final days = _tracksExpiry(item) ? item.daysUntilExpiry : null;
    final (String, Color)? expiry = switch (days) {
      null => null,
      < -1 => ('Caducó hace ${-days} días', AppColors.expired),
      -1 => ('Caducó ayer', AppColors.expired),
      0 => ('Caduca hoy', AppColors.expired),
      1 => ('Caduca mañana', AppColors.soon),
      <= 3 => ('Caduca en $days días', AppColors.soon),
      _ => ('$days días', AppColors.fresh),
    };
    final zoneLabel = showZone
        ? KitchenZone.values.firstWhere((z) => z.matches(item)).label
        : null;
    // Lo contable se cambia con − / + en la fila; el resto, en "Editar".
    final stepUnit = shoppingQtyNext(1, item.unit, up: true) == 2;
    final subtitle = [
      if (!stepUnit) inventoryQtyLabel(item.quantity, item.unit),
      ?zoneLabel,
      if (item.isStaple) 'No se compra',
    ].where((t) => t.isNotEmpty).join(' · ');

    // Fondo opaco: al deslizar, el color de la acción no se ve a través.
    final row = Material(
      color: AppColors.card,
      child: InkWell(
        onTap: () => _openItemActions(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              // Tocar la foto permite cambiarla, como en la compra.
              Semantics(
                button: true,
                label: 'Cambiar foto',
                child: GestureDetector(
                  onTap: () => _changePhoto(item),
                  child: FoodImage(
                    name: item.name,
                    itemType: item.itemType,
                    imageUrl: item.imageUrl,
                    size: 52,
                    radius: 14,
                    forceIllustration: item.category == 'Especias',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoppingCleanName(item.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                    // Insignia de caducidad bajo el nombre: no compite por
                    // ancho con el − / +.
                    if (expiry != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: expiry.$2.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          expiry.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: expiry.$2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (stepUnit) ...[
                const SizedBox(width: 8),
                QuantityStepper(
                  label: shoppingQtyLabel(item.quantity, item.unit),
                  // Bajar del último lo da por consumido hoy (con deshacer).
                  onMinus: item.quantity <= 1
                      ? () => _consume(item)
                      : () => _setQuantity(item, item.quantity - 1),
                  onPlus: () => _setQuantity(item, item.quantity + 1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    // Derecha: consumido hoy. Izquierda: a la lista de la compra.
    return SwipeAction(
      key: ValueKey(item.id),
      radius: 0,
      toRight: item.itemType == 'comida'
          ? SwipeSide(
              icon: Icons.check_rounded,
              color: AppColors.done,
              label: 'Consumido',
              onTrigger: () => _consume(item),
            )
          : null,
      toLeft: SwipeSide(
        icon: Icons.add_shopping_cart_rounded,
        color: AppColors.terracotta,
        label: 'A la compra',
        onTrigger: () => _addToShopping(item),
      ),
      child: row,
    );
  }

  Future<void> _setQuantity(InventoryItem item, double quantity) async {
    HapticFeedback.selectionClick();
    try {
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: item.id,
          changes: {'quantity': quantity},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, 'No se pudo actualizar'))),
      );
    }
  }

  Future<void> _addToShopping(InventoryItem item) async {
    try {
      await _restockDepletedStaple(item, previousQty: item.quantity);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(e, 'No pude añadir ${item.name} a la compra'),
          ),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Menú de limpieza: quitar lo caducado (de toda la cocina), vaciar la zona
  /// que se ve o vaciarlo todo. Vaciar pide confirmación.
  Widget _cleanupMenu(List<InventoryItem> all, KitchenZone? zone) {
    final expired = all
        .where(
          (i) => _tracksExpiry(i) && i.expiryStatus == ExpiryStatus.caducado,
        )
        .toList();
    final inZone = zone == null
        ? <InventoryItem>[]
        : all.where(zone.matches).toList();
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      icon: Icon(Icons.more_horiz_rounded, color: AppColors.ink),
      color: AppColors.card,
      onSelected: (v) => switch (v) {
        'expired' => _deleteMany(
          expired,
          done: expired.length == 1
              ? 'Caducado eliminado'
              : '${expired.length} caducados eliminados',
        ),
        'history' => _openHistory(),
        'zone' => _confirmEmpty(inZone, zone!.label),
        _ => _confirmEmpty(all, 'Mi cocina'),
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'history',
          child: Text('Lo que se ha gastado'),
        ),
        PopupMenuItem(
          value: 'expired',
          enabled: expired.isNotEmpty,
          child: Text(
            expired.isEmpty
                ? 'Nada caducado'
                : 'Eliminar caducados (${expired.length})',
          ),
        ),
        if (inZone.isNotEmpty)
          PopupMenuItem(
            value: 'zone',
            child: Text(
              'Vaciar ${zone!.label}',
              style: TextStyle(color: AppColors.expired),
            ),
          ),
        PopupMenuItem(
          value: 'all',
          child: Text(
            'Vaciar Mi cocina',
            style: TextStyle(color: AppColors.expired),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmEmpty(List<InventoryItem> items, String where) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Vaciar $where?'),
        content: Text('Se eliminarán ${items.length} productos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expired,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _deleteMany(items, done: '${items.length} productos eliminados');
    }
  }

  /// Borra [items] de forma optimista y ofrece deshacer (los vuelve a crear).
  Future<void> _deleteMany(
    List<InventoryItem> items, {
    required String done,
  }) async {
    if (items.isEmpty) return;
    HapticFeedback.mediumImpact();
    try {
      for (final item in items) {
        await _repo.applyLocalWrite(
          buildDeleteOp(
            table: kInventoryTable,
            id: item.id,
            nowMillis: DateTime.now().millisecondsSinceEpoch,
            seq: _nextSeq(),
          ),
        );
      }
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(done),
          // Con acción Flutter la deja fija; que se vaya sola.
          persist: false,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              for (final item in items) {
                await _applyUpsert(item, editing: false);
              }
            },
          ),
        ),
      );
    } catch (e) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo eliminar')),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Menú de acciones de un producto (pulsación larga o toque): marcar/quitar
  /// "no comprar", editar y eliminar.
  Future<void> _openItemActions(InventoryItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.woodDark),
              title: const Text('Editar'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            if (item.itemType == 'comida')
              ListTile(
                leading: Icon(
                  item.isStaple
                      ? Icons.add_shopping_cart
                      : Icons.remove_shopping_cart,
                  color: AppColors.woodDark,
                ),
                title: Text(
                  item.isStaple
                      ? 'Volver a añadir a la compra'
                      : 'No añadir a la compra',
                ),
                subtitle: item.isStaple
                    ? null
                    : const Text('Para básicos que siempre tienes'),
                onTap: () => Navigator.of(ctx).pop('staple'),
              ),
            if (item.itemType == 'comida')
              ListTile(
                leading: Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.woodDark,
                ),
                title: const Text('Consumido'),
                subtitle: item.isStaple
                    ? const Text('Lo añadiré a la compra')
                    : null,
                onTap: () => Navigator.of(ctx).pop('consumed'),
              ),
            ListTile(
              leading: Icon(Icons.image_outlined, color: AppColors.woodDark),
              title: const Text('Cambiar foto'),
              onTap: () => Navigator.of(ctx).pop('photo'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.expired),
              title: const Text('Eliminar'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final changed = await Navigator.of(context).push<InventoryItem>(
        MaterialPageRoute(builder: (_) => AddInventoryItemScreen(item: item)),
      );
      if (changed != null) await _applyUpsert(changed, editing: true);
    } else if (action == 'staple') {
      await _toggleStaple(item, !item.isStaple);
    } else if (action == 'consumed') {
      final picked = await _askConsumed(item);
      if (picked != null) {
        await _consume(item, on: picked.on, amount: picked.amount);
      }
    } else if (action == 'photo') {
      await _changePhoto(item);
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('¿Eliminar ${shoppingCleanName(item.name)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expired,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (ok == true) {
        HapticFeedback.mediumImpact();
        await _deleteItem(item);
      }
    }
  }

  /// Saca [amount] (todo, si es null) de la despensa como consumido el día
  /// [on] (hoy, si es null) y lo apunta en el historial. Se puede deshacer.
  Future<void> _consume(
    InventoryItem item, {
    DateTime? on,
    double? amount,
  }) async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final day = on ?? DateTime(now.year, now.month, now.day);
    final used = (amount ?? item.quantity).clamp(0, item.quantity).toDouble();
    final left = item.quantity - used;
    final name = shoppingCleanName(item.name);
    try {
      if (left <= 0 && item.isStaple) {
        // Básico: queda a 0 y vuelve a la compra (avisa él mismo).
        await _markDepleted(item);
      } else {
        await _repo.applyLocalWrite(
          left <= 0
              ? buildDeleteOp(
                  table: kInventoryTable,
                  id: item.id,
                  nowMillis: now.millisecondsSinceEpoch,
                  seq: _nextSeq(),
                )
              : buildUpdateOp(
                  table: kInventoryTable,
                  id: item.id,
                  changes: {'quantity': left},
                  nowMillis: now.millisecondsSinceEpoch,
                  seq: _nextSeq(),
                ),
        );
        await _reload();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo actualizar')),
          backgroundColor: AppColors.expired,
        ),
      );
      return;
    }
    final logId = await _logConsumed(item, used, day);
    if (!mounted || (left <= 0 && item.isStaple)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name, consumido ${_dayLabel(day)}'),
        persist: false,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            if (left <= 0) {
              await _applyUpsert(item, editing: false);
            } else {
              await _setQuantity(item, item.quantity);
            }
            if (logId != null) {
              try {
                await Supabase.instance.client
                    .from('pantry_log')
                    .delete()
                    .eq('id', logId);
              } catch (_) {}
            }
          },
        ),
      ),
    );
  }

  /// Apunta en el historial lo consumido. Devuelve su id (null si no hay red).
  // shortcut: el historial necesita conexión (no pasa por la cola offline);
  // meterlo en OfflineProvider si hace falta apuntarlo sin red.
  Future<String?> _logConsumed(
    InventoryItem item,
    double used,
    DateTime day,
  ) async {
    try {
      final homeId = item.homeId.isNotEmpty ? item.homeId : await _homeId();
      final row = await Supabase.instance.client
          .from('pantry_log')
          .insert({
            'home_id': homeId,
            'name': item.name,
            'quantity': used,
            'unit': item.unit,
            'reason': 'consumido',
            'used_on': day.toIso8601String().split('T').first,
          })
          .select('id')
          .single();
      return row['id'] as String?;
    } catch (e) {
      debugPrint('pantry_log: $e');
      return null;
    }
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'hoy';
    if (diff == 1) return 'ayer';
    return 'el ${d.day}/${d.month}';
  }

  /// Hoja "Consumido": qué día y, si hay varios, cuántos.
  Future<({DateTime on, double amount})?> _askConsumed(
    InventoryItem item,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var day = today;
    var amount = item.quantity;
    final countable =
        shoppingQtyNext(1, item.unit, up: true) == 2 && item.quantity > 1;
    return showModalBottomSheet<({DateTime on, double amount})>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final yesterday = today.subtract(const Duration(days: 1));
          final other = day != today && day != yesterday;
          Widget dayChip(String label, bool selected, VoidCallback onTap) =>
              ChoiceChip(
                label: Text(label),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.wood,
                backgroundColor: AppColors.card,
                onSelected: (_) => onTap(),
              );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shoppingCleanName(item.name),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¿Cuándo?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      dayChip('Hoy', day == today, () {
                        setSheet(() => day = today);
                      }),
                      dayChip('Ayer', day == yesterday, () {
                        setSheet(() => day = yesterday);
                      }),
                      dayChip(
                        other ? 'El ${day.day}/${day.month}' : 'Otro día',
                        other,
                        () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: day,
                            firstDate: today.subtract(const Duration(days: 60)),
                            lastDate: today,
                            helpText: '¿Qué día?',
                          );
                          if (picked != null) setSheet(() => day = picked);
                        },
                      ),
                    ],
                  ),
                  if (countable) ...[
                    const SizedBox(height: 16),
                    Text(
                      '¿Cuántos?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    QuantityStepper(
                      label: amount == item.quantity
                          ? 'Todo (${shoppingQtyLabel(amount, item.unit)})'
                          : shoppingQtyLabel(amount, item.unit),
                      onMinus: amount <= 1
                          ? null
                          : () => setSheet(() => amount -= 1),
                      onPlus: () => setSheet(
                        () => amount = (amount + 1).clamp(1, item.quantity),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TactileButton(
                      label: 'Consumido',
                      icon: Icons.check_rounded,
                      onPressed: () =>
                          Navigator.of(ctx).pop((on: day, amount: amount)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Cambia la foto del producto (cámara, galería, súper, generada o dibujo).
  Future<void> _changePhoto(InventoryItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ...productPhotoTiles(ctx, name: item.name, imageUrl: item.imageUrl),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    try {
      final homeId = item.homeId.isNotEmpty ? item.homeId : await _homeId();
      final keys = await HomeSupermarkets(Supabase.instance.client).load();
      if (!mounted) return;
      final url = await pickProductPhoto(
        context,
        action,
        homeId: homeId,
        name: item.name,
        imageUrl: item.imageUrl,
        supermarketKey: keys.keys.isEmpty ? null : keys.keys.first,
      );
      if (url == null) return;
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: item.id,
          changes: {'image_url': url},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, 'No se pudo cambiar la foto'))),
      );
    }
  }

  /// Lo que ha salido de la despensa estas semanas y qué día.
  Future<void> _openHistory() async {
    final rows = Supabase.instance.client
        .from('pantry_log')
        .select('name, quantity, unit, reason, used_on')
        .order('used_on', ascending: false)
        .order('created_at', ascending: false)
        .limit(60);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => FutureBuilder<List<Map<String, dynamic>>>(
          future: rows,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return snap.hasError
                  ? Center(
                      child: Text(
                        friendlyError(snap.error, 'No se pudo cargar'),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  'Lo que se ha gastado',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  Text(
                    'Aún no hay nada.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                for (final r in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: FoodImage(
                      name: (r['name'] ?? '').toString(),
                      size: 40,
                      radius: 10,
                    ),
                    title: Text(
                      shoppingCleanName((r['name'] ?? '').toString()),
                    ),
                    subtitle: Text(
                      [
                        inventoryQtyLabel(
                          (r['quantity'] as num?)?.toDouble(),
                          r['unit'] as String?,
                        ),
                        r['reason'] == 'receta' ? 'Al cocinar' : 'Consumido',
                      ].where((t) => t.isNotEmpty).join(' · '),
                    ),
                    trailing: Text(
                      _dayLabel(DateTime.parse(r['used_on'] as String)),
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
