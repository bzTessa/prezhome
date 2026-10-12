import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/ingredient.dart';
import 'models/inventory_item.dart';
import 'models/shopping_list_item.dart';
import 'services/food_photo_service.dart';
import 'services/offline_provider.dart';
import 'services/offline_repository.dart';
import 'services/price_memory.dart';
import 'services/shelf_life.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'models/shopping_category.dart';
import 'models/shopping_list.dart';
import 'models/supermarket.dart';
import 'services/home_supermarkets.dart';
import 'shopping_lists_overview_screen.dart';
import 'utils/offline_actions.dart';
import 'utils/practical_quantity.dart';
import 'utils/realtime_sync.dart';
import 'utils/shopping_categories.dart';
import 'utils/shopping_celebration.dart';
import 'utils/shopping_display.dart';
import 'utils/shopping_quick_add.dart';
import 'widgets/animations/confetti.dart';
import 'widgets/food_category_icon.dart';
import 'widgets/food_image.dart';
import 'widgets/miau_character.dart';
import 'widgets/pending_sync_indicator.dart';
import 'widgets/shopping/shopping_parts.dart';
import 'utils/friendly_error.dart';

/// Lista de la compra del hogar (compartida por RLS).
///
/// Muestra los items pendientes y, debajo, los ya comprados (atenuados).
/// Permite anadir cosas a mano, marcarlas como compradas, borrarlas y
/// generar la lista automaticamente a partir del plan semanal de comidas:
/// junta los ingredientes de las recetas planificadas de la semana y descuenta
/// lo que ya hay en el inventario cuando el match es fiable.
class ShoppingListScreen extends StatefulWidget {
  final bool embedded;
  const ShoppingListScreen({super.key, this.embedded = false});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Repositorios offline-first COMPARTIDOS (singletons): esta pantalla y su
  // gemela embebida/ruta comparten la misma caché y la misma cola en memoria.
  // La compra escribe en el repo de shopping_list_items; _addToPantry al marcar
  // comprado encola una op en el repo de inventory_items.
  final OfflineRepository _repo = OfflineProvider.instance.shopping;
  final OfflineRepository _inventoryRepo = OfflineProvider.instance.inventory;

  late Future<List<ShoppingListItem>> _itemsFuture;
  bool _generating = false;

  // Nº de cambios pendientes de sincronizar (cola no vacía) para el indicador
  // discreto. Se recalcula tras cada carga/escritura.
  int _pendingCount = 0;

  // Contador monótono para desempatar de forma estable el orden de las ops
  // encoladas (y para generar ids temporales de inserts offline).
  int _opSeq = 0;

  // Panel "YA EN EL CARRO" colapsable: arranca COLAPSADO porque lo ya comprado
  // deja de ser urgente (NN/g: lo que no apremia no debe ocupar scroll). La
  // usuaria puede desplegarlo para desmarcar o borrar.
  bool _cartExpanded = false;

  // Preferencias de vista de ESTE dispositivo (fotos, agrupar por pasillo).
  ShoppingViewPrefs _view = const ShoppingViewPrefs();

  // Súper del hogar (el primero es el principal) y el hogar al que pertenecen.
  List<String> _superKeys = [];
  String? _superHomeId;

  // ---- Multi-lista (migración 0045) --------------------------------------
  // Listas de la compra del hogar y lista ACTIVA. Las operaciones de la
  // pantalla (generar del plan, añadir, filtrar la vista) se refieren a la
  // lista activa. listId null = "Lista principal" (filas antiguas o sin lista).
  List<ShoppingList> _lists = [];
  String? _activeListId; // null => "Lista principal"

  // Categorías personalizadas del hogar (secciones). Se usan para la vista
  // agrupada y el CRUD. Pueden estar vacías si el hogar aún no las ha sembrado.
  List<ShoppingCategory> _categories = [];

  // Overrides manuales de expandido/colapsado por categoría de la compra
  // (clave = FoodCategory.name). Las categorías de pendientes arrancan TODAS
  // expandidas (lo que falta por comprar sí apremia); lo que la usuaria plega a
  // mano se recuerda aquí mientras la pantalla viva.
  final Map<String, bool> _catCollapsed = {};

  // Precios conocidos del hogar (para estimar el coste de la compra).
  Map<String, ProductPrice> _prices = {};

  // Guarda para disparar la celebración (Miau + confeti) SOLO en la transición
  // a 0 pendientes (de >0 a 0), no en cada rebuild ni al cambiar de tab en el
  // IndexedStack. La detección de la transición es lógica PURA
  // (ShoppingCelebrationGate) y ocurre al COMPLETAR el fetch, NO dentro de
  // build(): así un rebuild que no cambia el conteo (p. ej. borrar un comprado
  // estando ya en 0 pendientes) no reproduce el confeti. El flag se CONSUME al
  // construir el sliver para no repetir el rebote.
  final ShoppingCelebrationGate _celebrationGate = ShoppingCelebrationGate();

  // Canal Realtime de la lista de la compra del hogar. Se abre UNA sola vez en
  // initState (filtrado por home_id) y se cierra en dispose. Si el otro miembro
  // del hogar tacha o cambia un producto, recargamos la lista al instante. La
  // pantalla va embebida en DespensaTab dentro de un IndexedStack siempre vivo,
  // así que basta con abrirlo una vez y cerrarlo al destruir el estado.
  RealtimeChannel? _channel;

  // Guarda PURA que decide mostrar el aviso de "sin conexión en vivo" una sola
  // vez (sin spamear) y lo rearma al reconectar. La red vive aquí; la decisión,
  // en lib/utils/realtime_sync.dart (testeable).
  final RealtimeNoticeGate _noticeGate = RealtimeNoticeGate();

  @override
  void initState() {
    super.initState();
    // OFFLINE-FIRST: pintamos AL INSTANTE desde la caché local (sin esperar a
    // la red, aunque no haya cobertura) y, en paralelo, lanzamos el refresco
    // remoto que, al llegar, reemplaza la lista por la ya sincronizada.
    _itemsFuture = _loadFromCache();
    _refreshFromRemote();
    _subscribeRealtime();
    _loadListsAndCategories();
    _loadViewPrefs();
    _loadSupermarkets();
  }

  /// Siguiente número de secuencia para encolar/identificar ops de forma
  /// estable (monótono mientras viva la pantalla).
  int _nextSeq() => _opSeq++;

  /// Convierte las filas crudas (de la caché o del remoto) en modelos,
  /// aplicando el MISMO orden que usaba la consulta a Supabase: primero los
  /// pendientes y, dentro de cada grupo, por fecha de creación ascendente.
  List<ShoppingListItem> _rowsToItems(List<Map<String, dynamic>> rows) {
    final items = rows.map(ShoppingListItem.fromMap).toList();
    items.sort((a, b) {
      // checked=false antes que checked=true.
      final byChecked = (a.checked ? 1 : 0).compareTo(b.checked ? 1 : 0);
      if (byChecked != 0) return byChecked;
      final da = a.createdAt;
      final db = b.createdAt;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return items;
  }

  /// Carga INSTANTÁNEA desde la caché local (último estado conocido + ops
  /// pendientes aplicadas de forma optimista). No toca la red.
  Future<List<ShoppingListItem>> _loadFromCache() async {
    final rows = await _repo.readCached();
    _pendingCount = _repo.pendingCount + _inventoryRepo.pendingCount;
    final items = _rowsToItems(rows);
    _registerCelebration(items);
    // Los precios conocidos del hogar son best-effort y no bloquean la carga
    // instantánea: se intentan al refrescar desde el remoto.
    return items;
  }

  /// Registra en el gate puro la transición a 0 pendientes (celebración) FUERA
  /// de build(), igual que hacía el fetch original.
  void _registerCelebration(List<ShoppingListItem> items) {
    final nPend = items.where((i) => !i.checked).length;
    final hayComprados = items.any((i) => i.checked);
    _celebrationGate.registerFetch(
      currentPending: nPend,
      hasPurchased: hayComprados,
    );
  }

  /// Refresca desde Supabase (fetch + merge con pendientes + guardar caché) y,
  /// de paso, drena la cola si hay red. Si falla (sin cobertura) cae de vuelta
  /// a la caché sin romper la UI. Nunca usamos arrow con Future en setState:
  /// calculamos los datos antes y luego setState con cuerpo de bloque.
  Future<void> _refreshFromRemote() async {
    try {
      final rows = await _repo.refreshFromRemote();
      // Aprovechamos que hay red para intentar drenar también el inventario
      // (p. ej. los artículos que pasaron de la compra a la despensa offline).
      await _inventoryRepo.tryDrain();
      final items = _rowsToItems(rows);
      await _loadPrices();
      if (!mounted) return;
      _registerCelebration(items);
      final pending = _repo.pendingCount + _inventoryRepo.pendingCount;
      setState(() {
        _itemsFuture = Future.value(items);
        _pendingCount = pending;
      });
    } catch (_) {
      // Sin conexión: nos quedamos con lo que ya pintamos desde la caché.
    }
  }

  /// Carga best-effort de los precios conocidos del hogar para estimar coste.
  Future<void> _loadPrices() async {
    try {
      final homeId = await _homeId();
      _prices = await PriceMemory(_client).loadAll(homeId);
    } catch (_) {
      _prices = {};
    }
  }

  /// Carga best-effort las listas y categorías del hogar (migración 0045) y, si
  /// hace falta, SIEMBRA las categorías por defecto en español (idempotente: no
  /// duplica si ya existen). No bloquea la pantalla: si falla (sin red o sin la
  /// migración aplicada todavía) la lista sigue funcionando con list_id null
  /// (Lista principal) y categoría de texto libre. Nunca lanza hacia la UI.
  Future<void> _loadListsAndCategories() async {
    try {
      final homeId = await _homeId();

      final listRows = await _client
          .from('shopping_lists')
          .select()
          .eq('home_id', homeId)
          .order('created_at');
      final lists = (listRows as List)
          .map((m) => ShoppingList.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();

      var catRows = await _client
          .from('shopping_categories')
          .select()
          .eq('home_id', homeId)
          .order('position');
      // Seed idempotente de categorías por defecto si el hogar no tiene ninguna.
      if ((catRows as List).isEmpty) {
        await _seedDefaultCategories(homeId);
        catRows = await _client
            .from('shopping_categories')
            .select()
            .eq('home_id', homeId)
            .order('position');
      }
      final categories = (catRows as List)
          .map(
            (m) =>
                ShoppingCategory.fromMap(Map<String, dynamic>.from(m as Map)),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _lists = lists;
        _categories = categories;
        // Si la lista activa ya no existe, volvemos a la principal.
        if (_activeListId != null && !lists.any((l) => l.id == _activeListId)) {
          _activeListId = null;
        }
      });
    } catch (_) {
      // Sin migración aplicada / sin red: seguimos con Lista principal.
    }
  }

  /// Siembra las categorías por defecto (en español) para el hogar. Best-effort
  /// e idempotente a nivel de pantalla: solo se llama cuando no hay ninguna.
  Future<void> _seedDefaultCategories(String homeId) async {
    try {
      final names = defaultCategoryNames();
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < names.length; i++) {
        rows.add(
          ShoppingCategory(
            homeId: homeId,
            name: names[i],
            position: i,
          ).toInsertMap(),
        );
      }
      await _client.from('shopping_categories').insert(rows);
    } catch (_) {
      // Si falla el seed, no pasa nada: la UI tolera categorías vacías.
    }
  }

  /// Abre el canal Realtime filtrado por el hogar del usuario. Resuelve el
  /// home_id sin bloquear la UI (la lista ya se está cargando por su cuenta).
  /// Ante cualquier insert/update/delete recarga la lista de forma idempotente
  /// (reusa _reload, que vuelve a consultar la BD): así la escritura propia y
  /// su "eco" Realtime convergen al MISMO estado, sin duplicados ni parpadeo.
  ///
  /// Esta pantalla se instancia DOS veces: embebida en DespensaTab (IndexedStack
  /// siempre vivo) y como ruta propia empujada desde HomeTab. Para que cada
  /// estado tenga SU canal (y no compartan topic, lo que haría que un
  /// removeChannel tirara el canal del otro), el topic incluye un id único por
  /// instancia (identityHashCode): cada estado abre y cierra el suyo.
  Future<void> _subscribeRealtime() async {
    try {
      // Resolvemos el hogar SIN pasar por el aviso de "sin conexión": que no
      // haya sesión o perfil no es un fallo de conectividad, solo significa que
      // no hay nada que escuchar todavía (igual que en tasks_screen).
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null || !mounted) return;
      final channel = _client
          .channel(
            'public:shopping_list_items:$homeId:${identityHashCode(this)}',
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shopping_list_items',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'home_id',
              value: homeId,
            ),
            callback: (_) {
              if (!mounted) return;
              // Un eco remoto refresca vía refreshFromRemote (fetch + merge con
              // pendientes), de modo que NO borre un cambio local todavía sin
              // sincronizar.
              _refreshFromRemote();
            },
          )
          .subscribe((status, [error]) {
            _onChannelStatus(status);
          });
      _channel = channel;
    } catch (_) {
      // Abrir el canal puede fallar sin red: no pasa nada, la pantalla sigue
      // funcionando vía FutureBuilder/_reload. Avisamos una sola vez con el
      // gate puro. (La ausencia de sesión/hogar ya se trató arriba con un
      // return silencioso: no es un fallo de conectividad.)
      _notifyRealtimeDown();
    }
  }

  /// Traduce el estado real de Supabase a nuestro estado PURO y, si el gate
  /// decide que hay que avisar, muestra el SnackBar discreto una sola vez.
  void _onChannelStatus(RealtimeSubscribeStatus status) {
    final RealtimeChannelState state;
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        state = RealtimeChannelState.subscribed;
        // Al (re)conectar el canal, la red responde: intentamos vaciar la cola
        // de cambios pendientes en segundo plano.
        _drainOnReconnect();
        break;
      case RealtimeSubscribeStatus.channelError:
        state = RealtimeChannelState.error;
        break;
      case RealtimeSubscribeStatus.closed:
        state = RealtimeChannelState.closed;
        break;
      case RealtimeSubscribeStatus.timedOut:
        state = RealtimeChannelState.timedOut;
        break;
    }
    if (_noticeGate.registerStatus(state)) {
      _showRealtimeDownNotice();
    }
  }

  /// Al (re)conectar el canal Realtime, intenta drenar las colas de compra e
  /// inventario (force para saltar la ventana de espera del gate) y refresca el
  /// contador de pendientes del indicador. No usamos arrow con Future en
  /// setState: calculamos antes y aplicamos en bloque.
  Future<void> _drainOnReconnect() async {
    try {
      await _repo.tryDrain(force: true);
      await _inventoryRepo.tryDrain(force: true);
    } catch (_) {
      // Si el drenado falla seguimos offline: la cola se conserva intacta.
    }
    if (!mounted) return;
    final pending = _repo.pendingCount + _inventoryRepo.pendingCount;
    setState(() {
      _pendingCount = pending;
    });
  }

  /// Marca el fallo en el gate y muestra el aviso una sola vez (usado cuando ni
  /// siquiera llegamos a suscribirnos).
  void _notifyRealtimeDown() {
    if (_noticeGate.registerStatus(RealtimeChannelState.error)) {
      _showRealtimeDownNotice();
    }
  }

  /// Aviso DISCRETO con diseño de tarjeta (sin fondo de error, sin tecnicismos)
  /// de que no hay sincronización en vivo. La app sigue funcionando al recargar.
  void _showRealtimeDownNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        content: const Text(
          'Sin conexión en vivo ahora mismo; se actualizará al recargar.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      _client.removeChannel(channel);
      _channel = null;
    }
    super.dispose();
  }

  /// Recarga tras una escritura optimista: repinta AL INSTANTE desde la caché
  /// (que ya incluye el cambio) y, en segundo plano, refresca desde el remoto
  /// para converger con el servidor y drenar la cola. Nunca usamos arrow con un
  /// Future en setState: calculamos los datos antes y aplicamos en bloque.
  Future<void> _reload() async {
    final rows = await _repo.readCached();
    final items = _rowsToItems(rows);
    final pending = _repo.pendingCount + _inventoryRepo.pendingCount;
    if (!mounted) return;
    _registerCelebration(items);
    setState(() {
      _itemsFuture = Future.value(items);
      _pendingCount = pending;
    });
    // Convergencia con el servidor y drenado en segundo plano.
    _refreshFromRemote();
  }

  /// Obtiene el home_id del usuario autenticado leyendo su perfil.
  Future<String> _homeId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No hay usuario autenticado';
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .single();
    final homeId = profile['home_id'] as String?;
    if (homeId == null) throw 'El usuario no esta asignado a ningun hogar.';
    return homeId;
  }

  Future<void> _toggleChecked(ShoppingListItem item, bool value) async {
    if (item.id == null) return;
    try {
      // Escritura OPTIMISTA vía el repositorio: parcheamos solo 'checked'. La
      // caché refleja el cambio al instante; el envío a Supabase se drena en
      // segundo plano. Encolamos antes de _addToPantry para conservar el orden.
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kShoppingTable,
          id: item.id!,
          changes: {'checked': value},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      // Al marcar como comprado, el producto pasa SOLO a la despensa (dedup por
      // nombre). Al desmarcar no lo quitamos del inventario (ya está en casa).
      if (value) {
        await _addToPantry(item);
      }
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo actualizar')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mete un artículo comprado en el inventario (despensa). Deduplica por
  /// nombre normalizado: si ya existe (en cualquier ubicación de comida), suma
  /// la cantidad; si no, crea uno nuevo en Despensa con caducidad estimada.
  /// Best-effort: si algo falla, no rompe el marcado como comprado.
  Future<void> _addToPantry(ShoppingListItem item) async {
    try {
      final homeId = await _homeId();
      final nKey = CategoryIcons.normalize(item.name);
      final isHome = item.itemType == 'hogar';

      // Dedup contra la DESPENSA CACHEADA (que ya incluye las ops pendientes):
      // así funciona también sin conexión y no se pierde el merge por nombre.
      final existing = await _inventoryRepo.readCached();

      // Dedup por nombre DENTRO del mismo tipo (no fusionar comida con hogar).
      String? foundId;
      double foundQty = 0;
      for (final m in existing) {
        final rowIsHome = (m['item_type'] ?? 'comida').toString() == 'hogar';
        if (rowIsHome != isHome) continue;
        if (CategoryIcons.normalize((m['name'] ?? '').toString()) == nKey) {
          foundId = m['id'] as String?;
          foundQty = (m['quantity'] as num?)?.toDouble() ?? 0;
          break;
        }
      }

      final addQty = item.quantity ?? 1;
      if (foundId != null) {
        // Ya existe en la despensa: sumamos cantidad vía UPDATE optimista.
        await _inventoryRepo.applyLocalWrite(
          buildUpdateOp(
            table: kInventoryTable,
            id: foundId,
            changes: {'quantity': foundQty + addQty},
            nowMillis: DateTime.now().millisecondsSinceEpoch,
            seq: _nextSeq(),
          ),
        );
      } else {
        // Ubicación: hogar -> 'Hogar'; comida -> la elegida (item.category) o,
        // si no hay, la deducida por el alimento. Caducidad solo para comida.
        final String location;
        if (isHome) {
          location = item.category ?? 'Hogar';
        } else {
          location = item.category ?? ShelfLife.suggestLocation(item.name);
        }
        final estimated = isHome
            ? null
            : ShelfLife.estimateDate(item.name, location);
        // Insert OPTIMISTA con id temporal local: la fila se ve en la despensa
        // al instante y se enviará a Supabase al drenar la cola.
        final now = DateTime.now().millisecondsSinceEpoch;
        final localId = newLocalId(nowMillis: now, seq: _nextSeq());
        final inv = InventoryItem(
          id: localId,
          homeId: homeId,
          name: item.name,
          category: location,
          itemType: item.itemType,
          quantity: addQty,
          unit: item.unit ?? 'unidades',
          kind: 'ingredient',
          expirationDate: estimated,
          imageUrl: item.imageUrl,
        );
        await _inventoryRepo.applyLocalWrite(
          buildInsertOp(
            table: kInventoryTable,
            id: localId,
            payload: inv.toCacheMap(),
            nowMillis: now,
            seq: _nextSeq(),
          ),
        );
      }
    } catch (e) {
      debugPrint('ShoppingList._addToPantry error: $e');
    }
  }

  Future<void> _deleteItem(ShoppingListItem item) async {
    if (item.id == null) return;
    try {
      // Delete OPTIMISTA: desaparece de la caché al instante y se envía al
      // drenar. Si el id era local (insert aún no sincronizado), la cola
      // colapsa ambas ops y no se manda nada al servidor.
      await _repo.applyLocalWrite(
        buildDeleteOp(
          table: kShoppingTable,
          id: item.id!,
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo eliminar')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Menú de acciones de un artículo (pulsación larga): cambiar foto o borrar.
  Future<void> _openItemActions(ShoppingListItem item) async {
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.woodDark,
              ),
              title: const Text('Elegir foto de la galería'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.image_search,
                color: AppColors.woodDark,
              ),
              title: const Text('Buscar otra foto'),
              onTap: () => Navigator.of(ctx).pop('auto'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text('Quitar de la lista'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'gallery':
        await _pickPhoto(item);
        break;
      case 'auto':
        await _regenPhoto(item);
        break;
      case 'delete':
        await _deleteItem(item);
        break;
    }
  }

  /// Sube una foto de la galería al bucket y la fija como foto del artículo.
  /// El bucket recipe-images se reutiliza (ya tiene políticas públicas).
  Future<void> _pickPhoto(ShoppingListItem item) async {
    if (item.id == null) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 82,
      );
      if (file == null) return;
      final homeId = await _homeId();
      final bytes = await file.readAsBytes();
      final ext = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final path = '$homeId/shop_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage
          .from('recipe-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
              upsert: false,
            ),
          );
      final url = _client.storage.from('recipe-images').getPublicUrl(path);
      // La foto ya está subida (requiere red); el cambio de image_url pasa por
      // el repositorio para que la caché lo refleje al instante.
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kShoppingTable,
          id: item.id!,
          changes: {'image_url': url},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      // Memorizamos la foto para ese alimento en la caché del hogar, de modo
      // que la próxima vez (y en la despensa) se reutilice.
      await FoodPhotoService(
        _client,
      ).rememberPhoto(homeId: homeId, name: item.name, url: url);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo subir la foto')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vuelve a buscar una foto automática para el artículo.
  Future<void> _regenPhoto(ShoppingListItem item) async {
    if (item.id == null) return;
    try {
      final homeId = await _homeId();
      final url = await FoodPhotoService(_client).resolveProductPhotoUrl(
        homeId: homeId,
        name: item.name,
        mode: item.itemType == 'comida' ? 'ingredient' : 'dish',
      );
      if (url == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No encontré una foto. Puedes poner una tuya.'),
          ),
        );
        return;
      }
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kShoppingTable,
          id: item.id!,
          changes: {'image_url': url},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo cambiar la foto')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Botón de elección de tipo (comida/hogar) para el diálogo de alta.
  Widget _typeChoice(
    String value,
    String label,
    IconData icon,
    String current,
    ValueChanged<String> onTap,
  ) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.wood : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.woodDark : AppColors.wood,
            width: 1.3,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog de alta manual: nombre + cantidad/unidad + tipo (comida/hogar).
  Future<void> _openAddItem() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    var itemType = 'comida';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            backgroundColor: AppColors.cream,
            title: const Text('Añadir a la lista'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tipo: comida u hogar/limpieza. Decide a qué parte del
                // inventario irá al comprarlo.
                Row(
                  children: [
                    Expanded(
                      child: _typeChoice(
                        'comida',
                        'Comida',
                        Icons.restaurant,
                        itemType,
                        (v) => setDialog(() => itemType = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _typeChoice(
                        'hogar',
                        'Hogar/Limpieza',
                        Icons.cleaning_services,
                        itemType,
                        (v) => setDialog(() => itemType = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Tomates / Detergente',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unidad (opcional)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Añadir'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      nameCtrl.dispose();
      qtyCtrl.dispose();
      unitCtrl.dispose();
      return;
    }

    final name = nameCtrl.text.trim();
    final qty = double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.'));
    final unit = unitCtrl.text.trim();
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();

    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío.')),
      );
      return;
    }

    await _addItem(
      name: name,
      quantity: qty,
      unit: unit.isEmpty ? null : unit,
      itemType: itemType,
    );
  }

  /// Alta rápida desde el campo "Añadir producto": interpreta "2 kg tomates"
  /// y deduce si es comida o de hogar/limpieza por el nombre.
  Future<void> _quickAdd(String text) async {
    final entry = parseQuickAdd(text);
    if (entry == null) return;
    final cat = CategoryIcons.categoryFor(entry.name);
    final isHome = cat == FoodCategory.limpieza || cat == FoodCategory.hogar;
    await _addItem(
      name: entry.name,
      quantity: entry.quantity,
      unit: entry.unit,
      itemType: isHome ? 'hogar' : 'comida',
    );
  }

  /// Añade un producto a la lista activa (alta optimista, offline-first).
  Future<void> _addItem({
    required String name,
    double? quantity,
    String? unit,
    required String itemType,
  }) async {
    final qty = quantity;
    try {
      final homeId = await _homeId();
      // Foto real del artículo. Para comida en modo "ingrediente crudo"; para
      // hogar como producto tal cual. Best-effort y cacheado por hogar.
      String? imageUrl;
      try {
        // Foto REAL de producto priorizando Open Food Facts (foto del envase)
        // y, si no hay, el banco de imágenes; respaldo final = ilustración
        // cozy en la UI. La elección se recuerda por producto en la caché.
        imageUrl = await FoodPhotoService(_client).resolveProductPhotoUrl(
          homeId: homeId,
          name: name,
          mode: itemType == 'comida' ? 'ingredient' : 'dish',
        );
      } catch (_) {
        imageUrl = null;
      }
      // Alta OPTIMISTA con id temporal local y created_at = ahora: la fila
      // aparece en la lista al instante (ordenada por fecha de creación) y se
      // enviará a Supabase al drenar la cola.
      final now = DateTime.now();
      final nowMillis = now.millisecondsSinceEpoch;
      final localId = newLocalId(nowMillis: nowMillis, seq: _nextSeq());
      final catName = defaultCategoryFor(name);
      final item = ShoppingListItem(
        id: localId,
        homeId: homeId,
        name: name,
        quantity: qty,
        unit: unit,
        source: 'manual',
        createdAt: now,
        itemType: itemType,
        imageUrl: imageUrl,
        category: catName,
        categoryId: _categoryIdForName(catName),
        listId: _activeListId,
      );
      await _repo.applyLocalWrite(
        buildInsertOp(
          table: kShoppingTable,
          id: localId,
          payload: item.toCacheMap(),
          nowMillis: nowMillis,
          seq: _nextSeq(),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo añadir')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Lunes de esta semana (igual que meal_plan_screen.dart).
  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  /// Clave de agregacion: nombre + unidad normalizados (trim + minusculas).
  String _aggKey(String name, String? unit) {
    final n = name.trim().toLowerCase();
    final u = (unit ?? '').trim().toLowerCase();
    return '$n|$u';
  }

  /// Construye un item 'auto' del plan aplicando la regla PURA de condimentos:
  /// los condimentos/especias se expresan SIEMPRE en unidades enteras ('1 ud'),
  /// nunca en cucharadas/cucharaditas/pizca/ml de aceite (lo pidió la usuaria).
  /// El resto de alimentos conserva su cantidad/unidad. Además asigna una
  /// `category` de texto coherente (secciones por defecto) para que al mostrar
  /// la lista agrupada caiga en la sección correcta; la lista activa se asigna
  /// aparte al insertar.
  ShoppingListItem _buildAutoItem(
    String homeId,
    String name,
    double? quantity,
    String? unit,
  ) {
    final practical = makePracticalForShopping(name, quantity, unit);
    final catName = defaultCategoryFor(name);
    return ShoppingListItem(
      homeId: homeId,
      name: name,
      quantity: practical.quantity,
      unit: practical.unit,
      source: 'auto',
      category: catName,
      categoryId: _categoryIdForName(catName),
      listId: _activeListId,
    );
  }

  /// Devuelve el id de la categoría del hogar cuyo nombre coincide (ignorando
  /// mayúsculas/acentos) con [name], o null si no existe (se tratará como "Sin
  /// categorizar"). Casa la categoría de texto por defecto con la fila sembrada.
  String? _categoryIdForName(String name) {
    final key = normalizeCategoryText(name);
    for (final c in _categories) {
      if (normalizeCategoryText(c.name) == key) return c.id;
    }
    return null;
  }

  /// Genera la lista desde el plan semanal. Suma los ingredientes de las
  /// recetas planificadas de la semana, descuenta lo que ya hay en inventario
  /// cuando el match es fiable y crea los que faltan con source='auto'.
  Future<void> _generarDesdePlan() async {
    setState(() => _generating = true);
    try {
      final homeId = await _homeId();

      // Plan de esta semana (desde el lunes).
      final start = _weekStart;
      final end = start.add(const Duration(days: 7));
      final planRes = await _client
          .from('meal_plan_entries')
          .select()
          .eq('home_id', homeId)
          .gte('plan_date', start.toIso8601String().split('T').first)
          .lt('plan_date', end.toIso8601String().split('T').first);

      // Recetas de las comidas NO saltadas con recipe_id no nulo.
      final recipeIds = <String>{};
      for (final row in (planRes as List)) {
        final map = row as Map<String, dynamic>;
        final skipped = (map['skipped'] as bool?) ?? false;
        final recipeId = map['recipe_id'] as String?;
        if (!skipped && recipeId != null) recipeIds.add(recipeId);
      }

      if (recipeIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay plan esta semana todavia.')),
        );
        return;
      }

      // Ingredientes de esas recetas.
      final ingRes = await _client
          .from('recipe_ingredients')
          .select()
          .inFilter('recipe_id', recipeIds.toList());
      final ingredients = (ingRes as List)
          .map((m) => Ingredient.fromMap(m as Map<String, dynamic>))
          .toList();

      // Agregar por nombre + unidad normalizados. Si alguna cantidad es null
      // mantenemos el item sin cantidad (no inventamos cifras).
      final agg = <String, _AggItem>{};
      for (final ing in ingredients) {
        final name = ing.name.trim();
        if (name.isEmpty) continue;
        final key = _aggKey(name, ing.unit);
        final existing = agg[key];
        if (existing == null) {
          agg[key] = _AggItem(
            name: name,
            unit: ing.unit,
            quantity: ing.quantity,
          );
        } else {
          if (existing.quantity == null || ing.quantity == null) {
            // Si alguna no tiene cantidad, no podemos sumar de forma fiable.
            existing.quantity = null;
          } else {
            existing.quantity = existing.quantity! + ing.quantity!;
          }
        }
      }

      // Inventario del hogar, indexado por nombre normalizado. Nos quedamos con
      // una entrada por nombre (si hay varias, basta con detectar que existe).
      // Incluimos is_staple para tratar los basicos "siempre en casa" como
      // siempre disponibles.
      final invRes = await _client
          .from('inventory_items')
          .select('name, quantity, unit, is_staple')
          .eq('home_id', homeId);
      final inventory = <String, _InvEntry>{};
      // Conjunto de nombres normalizados marcados como "siempre en casa".
      // Criterio de match: nombre normalizado (minusculas + sin acentos) con la
      // MISMA normalizacion de CategoryIcons.normalize, para que, por ejemplo,
      // "Pimienta" en inventario excluya "pimienta" del plan.
      final staples = <String>{};
      for (final row in (invRes as List)) {
        final map = row as Map<String, dynamic>;
        final name = (map['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final nKey = CategoryIcons.normalize(name);
        final qty = (map['quantity'] as num?)?.toDouble();
        final unit = (map['unit'] as String?)?.trim().toLowerCase();
        final isStaple = (map['is_staple'] as bool?) ?? false;
        if (isStaple) staples.add(nKey);
        // Si ya habia una entrada para ese nombre, la dejamos como esta (basta
        // con una para decidir si descontamos).
        inventory.putIfAbsent(nKey, () => _InvEntry(quantity: qty, unit: unit));
      }

      // Descontar lo que ya tenemos SOLO cuando el match es fiable. Ante
      // cualquier duda (unidad distinta o cantidad no comparable) NO
      // descontamos y mantenemos el ingrediente: es mejor comprar de mas que
      // quedarnos cortos.
      final faltan = <ShoppingListItem>[];
      for (final item in agg.values) {
        final nKey = CategoryIcons.normalize(item.name);

        // Basicos "siempre en casa": si el ingrediente coincide por nombre
        // normalizado con un item is_staple=true, lo tratamos como siempre
        // disponible y NO lo anadimos a la lista, por poca cantidad que pida la
        // receta (sal, pimienta, aceite...).
        if (staples.contains(nKey)) continue;

        final inv = inventory[nKey];

        if (inv != null &&
            item.quantity != null &&
            inv.quantity != null &&
            (item.unit ?? '').trim().toLowerCase() == (inv.unit ?? '')) {
          // Match fiable con unidades comparables: restamos.
          final restante = item.quantity! - inv.quantity!;
          if (restante <= 0) {
            // Ya tenemos suficiente, no hace falta comprarlo.
            continue;
          }
          faltan.add(_buildAutoItem(homeId, item.name, restante, item.unit));
        } else {
          // No es fiable descontar: lo anadimos tal cual.
          faltan.add(
            _buildAutoItem(homeId, item.name, item.quantity, item.unit),
          );
        }
      }

      // La lista de la compra usa ilustración cozy por categoría (no fotos
      // reales), así que no resolvemos fotos aquí: ahorra cuota de Unsplash y
      // evita las fotos genéricas/aleatorias de básicos abstractos.

      // Regeneracion sin duplicar: borramos solo los items 'auto' pendientes.
      // No tocamos los manuales ni los ya marcados como comprados.
      //
      // NOTA OFFLINE (deliberado): esta regeneracion REQUIERE CONEXION. Ya ha
      // leido el plan, los ingredientes y el inventario de la red (lineas de
      // arriba), asi que sin cobertura habria lanzado mucho antes. Este borrado
      // es masivo por filtro (home_id + source='auto' + checked=false), no por
      // id, por lo que NO encaja en la cola optimista por fila; va directo por
      // _client. Si no hay red, lanza y el catch de abajo aborta toda la
      // generacion sin dejar a medias (las altas optimistas solo ocurren
      // DESPUES, si este borrado tuvo exito). Es una operacion online-only por
      // naturaleza, no una omision.
      // Scope del borrado a la LISTA ACTIVA: solo regeneramos los 'auto'
      // pendientes de la lista en la que estamos (list_id null = Lista
      // principal, que se filtra con .is_). No tocamos las otras listas.
      final deleteQuery = _client
          .from('shopping_list_items')
          .delete()
          .eq('home_id', homeId)
          .eq('source', 'auto')
          .eq('checked', false);
      if (_activeListId == null) {
        // Filtro IS NULL vía el escape hatch .filter() (sintaxis cruda de
        // PostgREST), estable entre versiones del cliente.
        await deleteQuery.filter('list_id', 'is', null);
      } else {
        await deleteQuery.eq('list_id', _activeListId!);
      }

      if (faltan.isNotEmpty) {
        // Altas OPTIMISTAS por el repositorio: cada item 'auto' entra con un id
        // temporal local y created_at = ahora. Aparecen al instante y se drenan
        // a Supabase en segundo plano (y el refresco posterior converge con el
        // borrado de los 'auto' previos ya hecho en el servidor).
        for (final i in faltan) {
          final nowMillis = DateTime.now().millisecondsSinceEpoch;
          final localId = newLocalId(nowMillis: nowMillis, seq: _nextSeq());
          final withId = ShoppingListItem(
            id: localId,
            homeId: i.homeId,
            name: i.name,
            quantity: i.quantity,
            unit: i.unit,
            source: i.source,
            createdAt: DateTime.fromMillisecondsSinceEpoch(nowMillis),
            itemType: i.itemType,
            category: i.category,
            imageUrl: i.imageUrl,
            listId: i.listId,
            categoryId: i.categoryId,
          );
          await _repo.applyLocalWrite(
            buildInsertOp(
              table: kShoppingTable,
              id: localId,
              payload: withId.toCacheMap(),
              nowMillis: nowMillis,
              seq: _nextSeq(),
            ),
          );
        }
      }

      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            faltan.isEmpty
                ? 'Ya tienes todo lo del plan en el inventario.'
                : 'Añadidos ${faltan.length} productos desde el plan.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Lista de la compra')),
      body: FutureBuilder<List<ShoppingListItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }

          final all = snapshot.data ?? [];
          // Filtramos por la LISTA ACTIVA: list_id null = Lista principal.
          final items = all.where((i) => i.listId == _activeListId).toList();
          final pendientes = items.where((i) => !i.checked).toList();
          final comprados = items.where((i) => i.checked).toList();

          // Compra terminada: hay items y todos están marcados. Mostramos a
          // Miau celebrando (rebote + confeti al vaciar). La detección de la
          // transición ya se hizo al resolver el fetch (gate puro); aquí solo
          // se CONSUME, para no repetir el confeti en cada rebuild.
          final compraTerminada = pendientes.isEmpty && comprados.isNotEmpty;
          final celebrar = _celebrationGate.consume();

          final slivers = <Widget>[
            SliverToBoxAdapter(
              child: ShoppingSummaryHeader(
                listName: _activeListName,
                pending: pendientes.length,
                done: comprados.length,
                estimate: _estimateLabel(pendientes),
                generating: _generating,
                onTapList: _openListsOverview,
                onGenerate: _generarDesdePlan,
                onOptions: _openViewOptions,
                storeLabel: _superKeys.isEmpty
                    ? null
                    : Supermarket.labelFor(_superKeys.first),
                onTapStore: _pickSupermarket,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: ShoppingQuickAddBar(
                onSubmit: _quickAdd,
                onMore: _openAddItem,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            if (shouldShowPendingIndicator(_pendingCount))
              SliverToBoxAdapter(
                child: PendingSyncIndicator(pendingCount: _pendingCount),
              ),
            if (items.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _emptyState()),
            if (compraTerminada)
              SliverToBoxAdapter(child: _CompraCelebracion(celebrar: celebrar)),
            ..._buildPendientesSlivers(pendientes),
            if (comprados.isNotEmpty)
              SliverToBoxAdapter(child: _cartCard(comprados)),
          ];

          return CustomScrollView(
            slivers: [
              SliverPadding(
                // Abajo deja sitio a la barra de navegación flotante.
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Nombre visible de la lista ACTIVA ('Lista principal' si es la implícita).
  String get _activeListName {
    if (_activeListId == null) return 'Lista principal';
    for (final l in _lists) {
      if (l.id == _activeListId) return l.name;
    }
    return 'Lista principal';
  }

  /// Abre la vista general de listas (crear/elegir lista). Al volver, aplica la
  /// lista elegida como activa y refresca listas/categorías.
  Future<void> _openListsOverview() async {
    final selected = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (context) => ShoppingListsOverviewScreen(
          lists: _lists,
          activeListId: _activeListId,
        ),
      ),
    );
    if (!mounted) return;
    // El overview devuelve:
    //   - null  => back sin elegir: mantenemos la lista actual.
    //   - ''    => Lista principal (list_id null).
    //   - 'new:NOMBRE' => crear una lista nueva y activarla.
    //   - otro  => id de la lista elegida.
    if (selected != null) {
      if (selected.startsWith('new:')) {
        final name = selected.substring(4);
        final newId = await _createList(name);
        if (!mounted) return;
        setState(() => _activeListId = newId);
      } else {
        setState(() => _activeListId = selected.isEmpty ? null : selected);
      }
    }
    // Siempre recargamos por si se crearon listas nuevas.
    await _loadListsAndCategories();
    if (!mounted) return;
    await _reload();
  }

  /// Crea una lista nueva en el hogar (desde el overview). Devuelve su id o null
  /// si falla. Best-effort; muestra error amable si no se puede.
  Future<String?> _createList(String name, {String? color}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final homeId = await _homeId();
      final inserted = await _client
          .from('shopping_lists')
          .insert(
            ShoppingList(
              homeId: homeId,
              name: trimmed,
              color: color,
            ).toInsertMap(),
          )
          .select('id')
          .single();
      return inserted['id'] as String?;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo crear la lista')),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  /// Abre el gestor de categorías (crear, renombrar y reordenar). Al volver,
  /// recarga las categorías del hogar.
  Future<void> _openCategoriesManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShoppingCategoriesScreen(
          categories: _categories,
          onCreate: _createCategory,
          onRename: _renameCategory,
          onReorder: _persistCategoryOrder,
        ),
      ),
    );
    if (!mounted) return;
    await _loadListsAndCategories();
  }

  /// Crea una categoría nueva al final del orden. Best-effort.
  Future<void> _createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      final homeId = await _homeId();
      final nextPos = _categories.length;
      await _client
          .from('shopping_categories')
          .insert(
            ShoppingCategory(
              homeId: homeId,
              name: trimmed,
              position: nextPos,
            ).toInsertMap(),
          );
    } catch (_) {
      // Silencioso: el gestor recargará y, si no apareció, la usuaria reintenta.
    }
  }

  /// Renombra una categoría existente. Best-effort.
  Future<void> _renameCategory(ShoppingCategory category, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || category.id == null) return;
    try {
      await _client
          .from('shopping_categories')
          .update({'name': trimmed})
          .eq('id', category.id!);
    } catch (_) {
      // Silencioso.
    }
  }

  /// Persiste el nuevo orden (position) de las categorías tras reordenar.
  /// Best-effort: actualiza fila a fila.
  Future<void> _persistCategoryOrder(List<ShoppingCategory> ordered) async {
    try {
      for (var i = 0; i < ordered.length; i++) {
        final c = ordered[i];
        if (c.id == null) continue;
        await _client
            .from('shopping_categories')
            .update({'position': i})
            .eq('id', c.id!);
      }
    } catch (_) {
      // Silencioso.
    }
  }

  // ---- Supermercado principal ---------------------------------------------

  Future<void> _loadSupermarkets() async {
    final r = await HomeSupermarkets(_client).load();
    if (!mounted) return;
    setState(() {
      _superHomeId = r.homeId;
      _superKeys = r.keys;
    });
  }

  /// Elige dónde se compra. Se guarda como súper principal del hogar: lo
  /// usan también la IA al crear recetas y "Descubrir".
  Future<void> _pickSupermarket() async {
    final current = _superKeys.isEmpty ? null : _superKeys.first;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '¿Dónde compras normalmente? Las recetas que genere la IA '
                  'usarán productos fáciles de encontrar ahí.',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
              for (final s in Supermarket.all)
                ListTile(
                  title: Text(s.label),
                  trailing: s.key == current
                      ? const Icon(Icons.check, color: AppColors.sage)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(s.key),
                ),
            ],
          ),
        ),
      ),
    );
    final homeId = _superHomeId;
    if (picked == null || picked == current || homeId == null) return;
    try {
      final next = await HomeSupermarkets(
        _client,
      ).setPrimary(homeId, _superKeys, picked);
      if (mounted) setState(() => _superKeys = next);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar el supermercado. Inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  // ---- Vista: preferencias y opciones -------------------------------------

  Future<void> _loadViewPrefs() async {
    try {
      final raw = await OfflineProvider.instance.store.read(
        ShoppingViewPrefs.storageKey,
      );
      if (!mounted) return;
      setState(() => _view = ShoppingViewPrefs.decode(raw));
    } catch (_) {
      // Sin almacenamiento: se queda la vista por defecto.
    }
  }

  void _setView(ShoppingViewPrefs next) {
    setState(() => _view = next);
    OfflineProvider.instance.store
        .write(ShoppingViewPrefs.storageKey, next.encode())
        .catchError((_) {});
  }

  /// Hoja de opciones: cómo se ve la lista y accesos a listas y categorías.
  Future<void> _openViewOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(ShoppingViewPrefs next) {
            _setView(next);
            setSheet(() {});
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Agrupar por pasillo'),
                  subtitle: const Text('Verduras, carne, limpieza…'),
                  value: _view.groupByAisle,
                  onChanged: (v) => update(_view.copyWith(groupByAisle: v)),
                ),
                SwitchListTile(
                  title: const Text('Mostrar fotos de los productos'),
                  value: _view.showPhotos,
                  onChanged: (v) => update(_view.copyWith(showPhotos: v)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.list_alt_rounded),
                  title: const Text('Mis listas'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openListsOverview();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categorías'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openCategoriesManager();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Coste estimado de lo pendiente con los precios aprendidos de los tickets
  /// ("≈ 34,20 €"), o null si no conocemos ningún precio.
  String? _estimateLabel(List<ShoppingListItem> pendientes) {
    if (pendientes.isEmpty) return null;
    final est = PriceMemory.estimateCost([
      for (final i in pendientes) (name: i.name, quantity: i.quantity),
    ], _prices);
    if (est.priced == 0) return null;
    final total = est.total.toStringAsFixed(2).replaceAll('.', ',');
    return '≈ $total €';
  }

  // ---- Secciones -----------------------------------------------------------

  /// Pendientes agrupados por pasillo (orden del enum FoodCategory, de frescos
  /// a genéricos) o, si la vista no agrupa, una sola sección en orden de alta.
  /// El plegado por pasillo se recuerda mientras viva la pantalla.
  List<Widget> _buildPendientesSlivers(List<ShoppingListItem> pendientes) {
    if (pendientes.isEmpty) return const [];
    if (!_view.groupByAisle) {
      const key = '_todo';
      final expanded = !(_catCollapsed[key] ?? false);
      return [
        SliverToBoxAdapter(
          child: ShoppingSection(
            title: 'Por comprar',
            count: pendientes.length,
            expanded: expanded,
            onToggle: () => setState(() => _catCollapsed[key] = expanded),
            children: [for (final i in pendientes) _buildRow(i)],
          ),
        ),
      ];
    }

    final grupos = <FoodCategory, List<ShoppingListItem>>{};
    for (final item in pendientes) {
      final cat = CategoryIcons.categoryFor(item.name);
      grupos.putIfAbsent(cat, () => []).add(item);
    }
    return [
      for (final cat in FoodCategory.values)
        if (grupos[cat] case final items? when items.isNotEmpty)
          SliverToBoxAdapter(child: _aisleSection(cat, items)),
    ];
  }

  Widget _aisleSection(FoodCategory cat, List<ShoppingListItem> items) {
    final style = CategoryIcons.styleForCategory(cat);
    final expanded = !(_catCollapsed[cat.name] ?? false);
    return ShoppingSection(
      title: cat.label,
      count: items.length,
      icon: style.icon,
      iconColor: style.foreground,
      iconBackground: style.background,
      expanded: expanded,
      onToggle: () => setState(() => _catCollapsed[cat.name] = expanded),
      children: [for (final i in items) _buildRow(i)],
    );
  }

  /// "En el carro": arranca plegado (lo comprado ya no apremia) y permite
  /// quitar de golpe todo lo comprado.
  Widget _cartCard(List<ShoppingListItem> comprados) {
    return ShoppingSection(
      title: 'En el carro',
      count: comprados.length,
      icon: Icons.check_rounded,
      iconColor: AppColors.sage,
      iconBackground: AppColors.sageBg,
      expanded: _cartExpanded,
      onToggle: () => setState(() => _cartExpanded = !_cartExpanded),
      trailing: TextButton(
        onPressed: () => _clearChecked(comprados),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.woodDark,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Quitar'),
      ),
      children: [for (final i in comprados) _buildRow(i)],
    );
  }

  /// Quita de la lista todo lo ya comprado (ya está en la despensa).
  Future<void> _clearChecked(List<ShoppingListItem> comprados) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('¿Quitar lo comprado?'),
        content: Text(
          'Se quitarán ${comprados.length} productos de la lista. '
          'Lo que ya pasó a la despensa se queda allí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final item in comprados) {
      await _deleteItem(item);
    }
  }

  /// Fila de producto: tocar marca/desmarca, deslizar marca como comprado y
  /// mantener pulsado abre las acciones (cambiar foto, borrar).
  Widget _buildRow(ShoppingListItem item) {
    final done = item.checked;
    return Dismissible(
      key: ValueKey(item.id ?? item.name + item.hashCode.toString()),
      direction: done ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.sageBg,
        child: const Icon(Icons.check_circle_rounded, color: AppColors.sage),
      ),
      // Deslizar NO borra: marca como comprado y la fila pasa al carro al
      // recargar (por eso devolvemos false y no se desmonta aquí).
      confirmDismiss: (_) async {
        await _toggleChecked(item, true);
        return false;
      },
      child: ShoppingItemTile(
        name: shoppingCleanName(item.name),
        checked: done,
        quantityLabel: shoppingQtyLabel(item.quantity, item.unit),
        subtitle: item.source == 'auto' ? 'Del plan de la semana' : null,
        onToggle: () => _toggleChecked(item, !done),
        onLongPress: () => _openItemActions(item),
        leading: _view.showPhotos
            ? FoodImage(
                name: item.name,
                itemType: item.itemType,
                imageUrl: item.imageUrl,
                size: 34,
                radius: 10,
              )
            : null,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 110),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Tu lista está vacía',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Escribe arriba lo que necesitas o genérala desde el plan '
              'de la semana.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _generating ? null : _generarDesdePlan,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Generar desde el plan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.woodDark,
                side: const BorderSide(color: AppColors.wood),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Celebración cuando no quedan items por comprar. Muestra la tarjeta de
/// "Compra completada" con Miau celebrando y, cuando [celebrar] es `true` (solo
/// en la TRANSICIÓN a 0 pendientes), un REBOTE ELÁSTICO de Miau MÁS un CONFETI
/// POR CÓDIGO (CustomPainter, sin paquete ni assets).
///
/// Respeta "reducir movimiento": con [AppMotion.reduceMotionOf] en `true`
/// muestra solo el estado final estático (Miau + tarjeta) sin rebote ni
/// confeti. El confeti se autodestruye al terminar el burst.
class _CompraCelebracion extends StatefulWidget {
  /// `true` únicamente en la transición a 0 pendientes: dispara rebote+confeti.
  /// `false` para mostrar la tarjeta ya asentada (p. ej. al volver al tab).
  final bool celebrar;
  const _CompraCelebracion({required this.celebrar});

  @override
  State<_CompraCelebracion> createState() => _CompraCelebracionState();
}

class _CompraCelebracionState extends State<_CompraCelebracion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  // Muestra el confeti mientras dura su burst; se apaga al completarse.
  bool _confetiActivo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
      value: widget.celebrar ? 0 : 1,
    );
    // Rebote elástico de entrada de Miau.
    _scale = Tween<double>(
      begin: 0.6,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.celebrar && !AppMotion.reduceMotionOf(context)) {
      _confetiActivo = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotionOf(context);
    final animar = widget.celebrar && !reduceMotion;

    final miau = animar
        ? ScaleTransition(
            scale: _scale,
            child: const MiauCharacter(mood: MiauMood.celebrating, size: 72),
          )
        : const MiauCharacter(mood: MiauMood.celebrating, size: 72);

    final tarjeta = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: AppRadius.md),
      child: Row(
        children: [
          miau,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Compra completada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ya tienes todo lo de la lista. Miau esta orgulloso.',
                  style: TextStyle(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // El confeti se dibuja ENCIMA de la tarjeta pero sin ocupar hueco ni
    // bloquear toques (IgnorePointer dentro de ConfettiBurst). Solo cuando
    // procede y no hay reduce-motion.
    if (!_confetiActivo || reduceMotion) return tarjeta;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tarjeta,
        Positioned.fill(
          child: ConfettiBurst(
            onCompleted: () {
              if (mounted) setState(() => _confetiActivo = false);
            },
          ),
        ),
      ],
    );
  }
}

/// Acumulador temporal para agregar ingredientes por nombre + unidad.
class _AggItem {
  final String name;
  final String? unit;
  double? quantity;
  _AggItem({required this.name, this.unit, this.quantity});
}

/// Entrada de inventario reducida que usamos para decidir si descontar.
class _InvEntry {
  final double? quantity;
  final String? unit;
  _InvEntry({this.quantity, this.unit});
}
