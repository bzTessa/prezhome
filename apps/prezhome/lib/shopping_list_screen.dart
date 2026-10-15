import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/shopping_list_item.dart';
import 'services/food_photo_service.dart';
import 'services/offline_provider.dart';
import 'services/offline_repository.dart';
import 'services/price_memory.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'widgets/list_skeleton.dart';
import 'models/shopping_category.dart';
import 'models/shopping_list.dart';
import 'models/supermarket.dart';
import 'services/home_supermarkets.dart';
import 'services/plan_shopping.dart';
import 'services/product_photo_resolver.dart';
import 'services/shopping_checkout.dart';
import 'shopping_lists_overview_screen.dart';
import 'utils/offline_actions.dart';
import 'utils/realtime_sync.dart';
import 'utils/shopping_categories.dart';
import 'utils/shopping_celebration.dart';
import 'utils/shopping_display.dart';
import 'utils/shopping_quick_add.dart';
import 'scan_ticket_screen.dart';
import 'widgets/animations/celebrate.dart';
import 'widgets/animations/confetti.dart';
import 'widgets/animations/press_scale.dart';
import 'widgets/animations/spring_value.dart';
import 'widgets/animations/swipe_action.dart';
import 'widgets/food_category_icon.dart';
import 'widgets/empty_state.dart';
import 'widgets/food_image.dart';
import 'widgets/product_icons.dart';
import 'widgets/pending_sync_indicator.dart';
import 'widgets/product_search_sheet.dart';
import 'widgets/shopping/shopping_parts.dart';
import 'widgets/tactile_button.dart';
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

  // Última lista pintada: los cambios locales (marcar, quitar) se aplican
  // sobre ella AL INSTANTE, sin esperar a la red.
  List<ShoppingListItem>? _shown;

  // Los avisos en vivo llegan a ráfagas (p. ej. al poner fotos): se agrupan
  // en un solo refresco, y nunca se solapan dos refrescos.
  Timer? _realtimeDebounce;
  bool _refreshing = false;
  bool _refreshAgain = false;
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

  // Recién marcados: se quedan un momento en su sitio (tachados) antes de
  // pasar al carrito, por si el toque fue sin querer y hay que desmarcar.
  final Set<String> _settling = {};

  // "Lo habitual" recién añadido: el chip sigue a la vista con su check un
  // momento para poder añadir varios seguidos.
  final Set<String> _justAdded = {};

  // Confeti al terminar la compra.
  bool _finishConfetti = false;

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
    _shown = items;
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
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
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
        _shown = items;
        _itemsFuture = Future.value(items);
        _pendingCount = pending;
      });
      _upgradePhotosOnce(items);
    } catch (_) {
      // Sin conexión: nos quedamos con lo que ya pintamos desde la caché.
    } finally {
      _refreshing = false;
      if (_refreshAgain && mounted) {
        _refreshAgain = false;
        _refreshFromRemote();
      }
    }
  }

  /// Una vez por pantalla: a lo pendiente sin foto (o con foto de banco de
  /// imágenes) se le pone la del envase de Open Food Facts, en segundo plano.
  bool _photosUpgraded = false;
  void _upgradePhotosOnce(List<ShoppingListItem> items) {
    if (_photosUpgraded) return;
    final todo = [
      for (final i in items)
        if (!i.checked &&
            i.id != null &&
            !isLocalId(i.id!) &&
            // Las de OFF se comprueban (y se cambian si no son ese producto).
            ((i.imageUrl ?? '').isEmpty ||
                isStockPhoto(i.imageUrl) ||
                isSharablePhoto(i.imageUrl!)))
          i,
    ].take(25).toList();
    if (todo.isEmpty) return;
    _photosUpgraded = true;
    _homeId()
        .then(
          (homeId) => PlanShoppingService(_client).fillMissingPhotos(
            homeId,
            todo,
            supermarketKey: _superKeys.isEmpty ? null : _superKeys.first,
          ),
        )
        .then((n) {
          if (n > 0 && mounted) _reload();
          return n;
        })
        .catchError((_) => 0);
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
      // Pasillos nuevos para los hogares que ya tenían categorías (una vez:
      // si la persona borra alguno, no vuelve mientras quede otro).
      final have = {
        for (final m in catRows) normalizeCategoryText('${m['name']}'),
      };
      if (!kNewShoppingCategories.any(
        (n) => have.contains(normalizeCategoryText(n)),
      )) {
        await _addNewCategories(homeId, catRows.length);
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

  Future<void> _addNewCategories(String homeId, int from) async {
    try {
      await _client.from('shopping_categories').insert([
        for (var i = 0; i < kNewShoppingCategories.length; i++)
          ShoppingCategory(
            homeId: homeId,
            name: kNewShoppingCategories[i],
            position: from + i,
          ).toInsertMap(),
      ]);
    } catch (_) {
      // Best-effort, como el seed.
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
              _realtimeDebounce?.cancel();
              _realtimeDebounce = Timer(const Duration(milliseconds: 600), () {
                if (mounted) _refreshFromRemote();
              });
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
    _realtimeDebounce?.cancel();
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
      _shown = items;
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

  /// Pinta al momento la lista con [changes] aplicados a [item].
  void _showChanged(ShoppingListItem item, Map<String, dynamic> changes) {
    final current = _shown;
    if (current == null) return;
    final updated = [
      for (final i in current)
        if (i.id == item.id)
          ShoppingListItem.fromMap({...i.toCacheMap(), ...changes})
        else
          i,
    ];
    setState(() {
      _shown = updated;
      _itemsFuture = Future.value(updated);
    });
  }

  /// Cambia la cantidad desde la pastilla − / + de la fila.
  Future<void> _setQuantity(ShoppingListItem item, double quantity) async {
    if (item.id == null) return;
    HapticFeedback.selectionClick();
    _showChanged(item, {'quantity': quantity});
    try {
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kShoppingTable,
          id: item.id!,
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

  /// Termina la compra: celebra y quita de la lista lo del carrito (ya está
  /// en la despensa desde que se marcó). Se puede deshacer.
  Future<void> _finishShopping(List<ShoppingListItem> comprados) async {
    HapticFeedback.mediumImpact();
    if (!AppMotion.reduceMotionOf(context)) {
      Celebrate.show(context);
      setState(() => _finishConfetti = true);
    }
    await _clearChecked(comprados);
  }

  void _openScanTicket() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScanTicketScreen()));
  }

  Future<void> _toggleChecked(ShoppingListItem item, bool value) async {
    if (item.id == null) return;
    // Primero se ve el cambio; el guardado va detrás. Al comprar, el producto
    // pasa a su zona de la despensa.
    _showChanged(item, {'checked': value});
    final id = item.id!;
    if (value) {
      HapticFeedback.mediumImpact();
      _settling.add(id);
      Timer(const Duration(milliseconds: 900), () {
        if (mounted && _settling.remove(id)) setState(() {});
      });
    } else {
      _settling.remove(id);
    }
    try {
      final homeId = await _homeId();
      await ShoppingCheckout().setBought(item, value, homeId: homeId);
      await _reload();
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

  /// Da por comprado todo lo pendiente de la lista activa de una vez.
  Future<void> _checkAll() async {
    final current = _shown;
    if (current == null) return;
    final pending = current
        .where((i) => !i.checked && i.listId == _activeListId)
        .length;
    if (pending == 0) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _shown = [
        for (final i in current)
          if (!i.checked && i.listId == _activeListId)
            ShoppingListItem.fromMap({...i.toCacheMap(), 'checked': true})
          else
            i,
      ];
      _itemsFuture = Future.value(_shown!);
    });
    try {
      final homeId = await _homeId();
      await ShoppingCheckout().markAllBought(
        homeId: homeId,
        listId: _activeListId,
      );
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$pending productos guardados en la despensa')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, 'No se pudo actualizar'))),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_camera_outlined,
                color: AppColors.woodDark,
              ),
              title: const Text('Hacer una foto'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.woodDark,
              ),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: Icon(
                Icons.storefront_rounded,
                color: AppColors.woodDark,
              ),
              title: const Text('Elegir producto del súper'),
              onTap: () => Navigator.of(ctx).pop('store'),
            ),
            if (ProductIcons.photoKeyFor(item.name) != null)
              ListTile(
                leading: Icon(Icons.image_outlined, color: AppColors.woodDark),
                title: const Text('Generar foto'),
                onTap: () => Navigator.of(ctx).pop('generate'),
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.expired),
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
      case 'camera':
        await _pickPhoto(item, ImageSource.camera);
        break;
      case 'gallery':
        await _pickPhoto(item, ImageSource.gallery);
        break;
      case 'store':
        await _pickStoreProductPhoto(item);
        break;
      case 'generate':
        await _generatePhoto(item);
        break;
      case 'delete':
        await _removeWithUndo([
          item,
        ], 'Quitado "${shoppingCleanName(item.name)}"');
        break;
    }
  }

  /// Sube una foto de la galería al bucket y la fija como foto del artículo.
  /// El bucket recipe-images se reutiliza (ya tiene políticas públicas).
  Future<void> _pickPhoto(ShoppingListItem item, ImageSource source) async {
    if (item.id == null) return;
    try {
      final file = await _picker.pickImage(
        source: source,
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
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Crea otra foto genérica del producto (sustituye la compartida).
  Future<void> _generatePhoto(ShoppingListItem item) async {
    if (item.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Creando la foto…'),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      final url = await ProductPhotoResolver(
        _client,
      ).genericPhoto(item.name, again: true);
      messenger.hideCurrentSnackBar();
      if (url == null) throw Exception('Sin foto');
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kShoppingTable,
          id: item.id!,
          changes: {'image_url': url},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      final homeId = await _homeId();
      await FoodPhotoService(
        _client,
      ).rememberPhoto(homeId: homeId, name: item.name, url: url);
      await _reload();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo crear la foto')),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Pone como foto la del envase de un producto del súper.
  Future<void> _pickStoreProductPhoto(ShoppingListItem item) async {
    if (item.id == null) return;
    final product = await showProductSearchSheet(
      context,
      initialQuery: shoppingCleanName(item.name),
      supermarketKey: _superKeys.isEmpty ? null : _superKeys.first,
    );
    final url = product?.imageUrl;
    if (url == null || !mounted) return;
    try {
      await _repo.applyLocalWrite(
        buildUpdateOp(
          table: kShoppingTable,
          id: item.id!,
          changes: {'image_url': url},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      final homeId = await _homeId();
      await FoodPhotoService(
        _client,
      ).rememberPhoto(homeId: homeId, name: item.name, url: url);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, 'No se pudo cambiar la foto'))),
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
          borderRadius: BorderRadius.circular(16),
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
              style: TextStyle(
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
            scrollable: true,
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
                    hintText: 'Producto',
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
                          labelText: 'Cantidad',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unidad'),
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
    final isHome = CategoryIcons.isHousehold(cat);
    await _addItem(
      name: entry.name,
      quantity: entry.quantity,
      unit: entry.unit,
      itemType: isHome ? 'hogar' : 'comida',
    );
  }

  /// Busca el producto en el súper principal y lo añade con su foto real.
  /// Si no se elige ninguno, se añade el texto tal cual (con foto
  /// representativa).
  Future<void> _searchProduct(String text) async {
    final entry = parseQuickAdd(text);
    final product = await showProductSearchSheet(
      context,
      initialQuery: entry?.name ?? text,
      supermarketKey: _superKeys.isEmpty ? null : _superKeys.first,
    );
    if (!mounted) return;
    if (product == null) {
      if (text.trim().isNotEmpty) await _quickAdd(text);
      return;
    }
    final cat = CategoryIcons.categoryFor(product.name);
    final isHome = CategoryIcons.isHousehold(cat);
    await _addItem(
      name: product.displayName,
      quantity: entry?.quantity,
      unit: entry?.unit,
      itemType: isHome ? 'hogar' : 'comida',
      imageUrl: product.imageUrl,
    );
  }

  /// Añade un producto a la lista activa (alta optimista, offline-first).
  /// Con [imageUrl] (producto elegido del súper) no se busca foto.
  Future<void> _addItem({
    required String name,
    double? quantity,
    String? unit,
    required String itemType,
    String? imageUrl,
  }) async {
    final qty = quantity;
    final productPhoto = imageUrl;
    try {
      final homeId = await _homeId();
      // Foto real del artículo. Para comida en modo "ingrediente crudo"; para
      // hogar como producto tal cual. Best-effort y cacheado por hogar.
      String? imageUrl = productPhoto;
      if (imageUrl != null) {
        // Se recuerda para la próxima vez que se escriba este producto.
        await FoodPhotoService(
          _client,
        ).rememberPhoto(homeId: homeId, name: name, url: imageUrl);
      } else {
        // Foto del envase en Open Food Facts (o la ya guardada). Si tarda,
        // el producto entra sin foto y se le pone después.
        imageUrl = await ProductPhotoResolver(_client)
            .photoFor(
              homeId: homeId,
              name: name,
              supermarketKey: _superKeys.isEmpty ? null : _superKeys.first,
            )
            .timeout(const Duration(seconds: 4), onTimeout: () => null);
      }
      // Alta OPTIMISTA con id temporal local y created_at = ahora: la fila
      // aparece en la lista al instante (ordenada por fecha de creación) y se
      // enviará a Supabase al drenar la cola.
      final now = DateTime.now();
      final nowMillis = now.millisecondsSinceEpoch;
      final localId = newLocalId(nowMillis: nowMillis, seq: _nextSeq());
      final catName = defaultCategoryFor(name, itemType: itemType);
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
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Lunes de esta semana (igual que meal_plan_screen.dart).
  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
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

  /// Genera la lista desde el plan semanal: lo que piden las recetas menos
  /// lo que ya hay en casa, cada producto con su foto. Necesita conexión.
  Future<void> _generarDesdePlan() async {
    setState(() => _generating = true);
    try {
      final homeId = await _homeId();
      final service = PlanShoppingService(_client);
      final added = await service.syncFromPlan(
        homeId: homeId,
        from: _weekStart,
        to: _weekStart.add(const Duration(days: 7)),
        listId: _activeListId,
      );
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added.isEmpty
                ? 'Ya tienes en casa todo lo del plan'
                : 'Añadidos ${added.length} productos del plan',
          ),
        ),
      );
      // Las fotos que faltan se buscan después, sin bloquear la lista.
      if (added.any((i) => (i.imageUrl ?? '').isEmpty)) {
        service
            .fillMissingPhotos(
              homeId,
              added,
              supermarketKey: _superKeys.isEmpty ? null : _superKeys.first,
            )
            .then((n) {
              if (n > 0 && mounted) _reload();
            });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
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
          // Al refrescar se sigue viendo la lista anterior (sin parpadeo).
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }

          final all = snapshot.data ?? [];
          // Filtramos por la LISTA ACTIVA: list_id null = Lista principal.
          final items = all.where((i) => i.listId == _activeListId).toList();
          bool settling(ShoppingListItem i) => _settling.contains(i.id);
          final pendientes = items
              .where((i) => !i.checked || settling(i))
              .toList();
          final comprados = items
              .where((i) => i.checked && !settling(i))
              .toList();

          // Compra terminada: hay items y todos están marcados. Mostramos a
          // Miau celebrando (rebote + confeti al vaciar). La detección de la
          // transición ya se hizo al resolver el fetch (gate puro); aquí solo
          // se CONSUME, para no repetir el confeti en cada rebuild.
          final compraTerminada = pendientes.isEmpty && comprados.isNotEmpty;
          final porComprar = pendientes.where((i) => !i.checked).toList();
          final celebrar = _celebrationGate.consume();

          final slivers = <Widget>[
            SliverToBoxAdapter(
              child: ShoppingSummaryHeader(
                listName: _activeListName,
                pending: pendientes.length,
                done: comprados.length,
                estimate: _estimate(porComprar),
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
                onSearch: _searchProduct,
              ),
            ),
            if (usualProducts(
                  [
                    for (final p in _prices.values)
                      (name: p.displayName, times: p.samples),
                  ],
                  porComprar
                      .map((i) => i.name)
                      .where((n) => !_justAdded.contains(n)),
                )
                case final usual when usual.isNotEmpty)
              SliverToBoxAdapter(child: _usualChips(usual)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            if (shouldShowPendingIndicator(_pendingCount))
              SliverToBoxAdapter(
                child: PendingSyncIndicator(pendingCount: _pendingCount),
              ),
            // Caja simple y no SliverFillRemaining: el hueco que queda cambia
            // al abrir el teclado.
            if (items.isEmpty) SliverToBoxAdapter(child: _emptyState()),
            if (compraTerminada)
              SliverToBoxAdapter(child: _CompraCelebracion(celebrar: celebrar)),
            ..._buildPendientesSlivers(pendientes),
            if (comprados.isNotEmpty)
              SliverToBoxAdapter(child: _cartCard(comprados)),
          ];

          final showBar = comprados.isNotEmpty;
          return Stack(
            children: [
              CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    // Abajo deja sitio a la barra de terminar la compra.
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      showBar ? 104 : 32,
                    ),
                    sliver: SliverMainAxisGroup(slivers: slivers),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _checkoutBar(comprados, visible: showBar),
              ),
              if (_finishConfetti)
                Positioned.fill(
                  child: ConfettiBurst(
                    onCompleted: () {
                      if (mounted) setState(() => _finishConfetti = false);
                    },
                  ),
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
          backgroundColor: AppColors.expired,
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
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Las recetas usarán productos de este súper.',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
              for (final s in Supermarket.all)
                ListTile(
                  title: Text(s.label),
                  trailing: s.key == current
                      ? Icon(Icons.check, color: AppColors.sage)
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

  /// Coste estimado de lo pendiente en euros con los precios aprendidos de
  /// los tickets, o null si no conocemos ningún precio.
  double? _estimate(List<ShoppingListItem> pendientes) {
    if (pendientes.isEmpty) return null;
    final est = PriceMemory.estimateCost([
      for (final i in pendientes) (name: i.name, quantity: i.quantity),
    ], _prices);
    if (est.priced == 0) return null;
    return est.total;
  }

  /// Barra flotante para terminar la compra (y escanear el ticket). Entra y
  /// sale desde abajo con un muelle.
  Widget _checkoutBar(
    List<ShoppingListItem> comprados, {
    required bool visible,
  }) {
    return IgnorePointer(
      ignoring: !visible,
      child: SpringValue(
        value: visible ? 0 : 1,
        spring: AppMotion.fluidBouncy,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, 120 * t),
          child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: child),
        ),
        child: Row(
          children: [
            Expanded(
              child: TactileButton(
                label: comprados.isEmpty
                    ? 'Terminar compra'
                    : 'Terminar compra (${comprados.length})',
                icon: Icons.kitchen_rounded,
                onPressed: () => _finishShopping(comprados),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Tooltip(
              message: 'Escanear ticket',
              child: Semantics(
                button: true,
                label: 'Escanear ticket',
                child: PressScale(
                  onTap: _openScanTicket,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: AppTheme.tactileDecoration(
                      radius: 999,
                      borderWidth: 2,
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Secciones -----------------------------------------------------------

  /// Pendientes agrupados por pasillo (orden del enum FoodCategory, de frescos
  /// a genéricos) o, si la vista no agrupa, una sola sección en orden de alta.
  /// El plegado por pasillo se recuerda mientras viva la pantalla.
  List<Widget> _buildPendientesSlivers(List<ShoppingListItem> pendientes) {
    if (pendientes.isEmpty) return const [];
    final porComprar = pendientes.where((i) => !i.checked).length;
    return [
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: porComprar == 0 ? null : _checkAll,
            icon: const Icon(Icons.done_all_rounded, size: 20),
            label: const Text('Todo comprado'),
            style: TextButton.styleFrom(foregroundColor: AppColors.done),
          ),
        ),
      ),
      ..._pendingSections(pendientes),
    ];
  }

  List<Widget> _pendingSections(List<ShoppingListItem> pendientes) {
    if (!_view.groupByAisle) {
      const key = '_todo';
      final expanded = !(_catCollapsed[key] ?? false);
      return [
        SliverToBoxAdapter(
          child: ShoppingSection(
            title: 'Por comprar',
            count: pendientes.where((i) => !i.checked).length,
            complete: pendientes.every((i) => i.checked),
            expanded: expanded,
            onToggle: () => setState(() => _catCollapsed[key] = expanded),
            children: [for (final i in pendientes) _buildRow(i)],
          ),
        ),
      ];
    }

    // Sin categorías del hogar (sin red o sin migrar): pasillos por defecto.
    if (_categories.isEmpty) {
      final grupos = <FoodCategory, List<ShoppingListItem>>{};
      for (final item in pendientes) {
        final cat = CategoryIcons.categoryFor(item.name);
        grupos.putIfAbsent(cat, () => []).add(item);
      }
      return [
        for (final cat in FoodCategory.values)
          if (grupos[cat] case final items? when items.isNotEmpty)
            SliverToBoxAdapter(
              child: _aisleSection(
                cat.label,
                CategoryIcons.styleForCategory(cat),
                items,
              ),
            ),
      ];
    }

    // En el orden de las categorías del hogar, que se puede cambiar en
    // Opciones → Categorías para seguir el recorrido de tu súper.
    final grupos = groupByHomeCategories(
      pendientes,
      [for (final c in _categories) (id: c.id, name: c.name)],
      categoryIdOf: (i) => i.categoryId,
      categoryNameOf: (i) => i.category,
      nameOf: (i) => i.name,
    );
    return [
      for (final (name, items) in grupos)
        SliverToBoxAdapter(
          child: _aisleSection(
            name,
            CategoryIcons.styleForCategory(CategoryIcons.categoryFor(name)),
            items,
          ),
        ),
    ];
  }

  /// "Lo habitual": lo que más compras, para añadirlo de un toque.
  Widget _usualChips(List<String> usual) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lo habitual',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in usual)
                QuickAddChip(
                  label: name,
                  added: _justAdded.contains(name),
                  onAdd: () => _addUsual(name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Añade un producto de "Lo habitual" y deja su chip con el check un
  /// momento, para seguir añadiendo sin perder el sitio.
  Future<void> _addUsual(String name) async {
    if (_justAdded.contains(name)) return;
    HapticFeedback.lightImpact();
    setState(() => _justAdded.add(name));
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _justAdded.remove(name)) setState(() {});
    });
    await _quickAdd(name);
  }

  Widget _aisleSection(
    String title,
    CategoryStyle style,
    List<ShoppingListItem> items,
  ) {
    final expanded = !(_catCollapsed[title] ?? false);
    return ShoppingSection(
      title: title,
      count: items.where((i) => !i.checked).length,
      complete: items.every((i) => i.checked),
      icon: style.icon,
      iconColor: style.foreground,
      iconBackground: style.background,
      expanded: expanded,
      onToggle: () => setState(() => _catCollapsed[title] = expanded),
      children: [for (final i in items) _buildRow(i)],
    );
  }

  /// "En el carrito": arranca plegado (lo comprado ya no apremia); se vacía
  /// con "Terminar compra".
  Widget _cartCard(List<ShoppingListItem> comprados) {
    return ShoppingSection(
      title: 'En el carrito',
      count: comprados.length,
      icon: Icons.shopping_cart_rounded,
      iconColor: AppColors.done,
      iconBackground: AppColors.sageBg,
      expanded: _cartExpanded,
      onToggle: () => setState(() => _cartExpanded = !_cartExpanded),
      children: [for (final i in comprados) _buildRow(i)],
    );
  }

  /// Quita de la lista todo lo ya comprado (ya está en la despensa). Sin
  /// pregunta previa: se puede deshacer.
  Future<void> _clearChecked(List<ShoppingListItem> comprados) =>
      _removeWithUndo(
        comprados,
        comprados.length == 1
            ? 'Quitado 1 producto'
            : 'Quitados ${comprados.length} productos',
      );

  /// Quita [items] al momento y ofrece "Deshacer" (los vuelve a añadir tal
  /// cual estaban).
  Future<void> _removeWithUndo(
    List<ShoppingListItem> items,
    String message,
  ) async {
    final targets = items.where((i) => i.id != null).toList();
    if (targets.isEmpty) return;
    final ids = {for (final i in targets) i.id!};
    final current = _shown;
    if (current != null) {
      setState(() {
        _shown = [
          for (final i in current)
            if (!ids.contains(i.id)) i,
        ];
        _itemsFuture = Future.value(_shown!);
      });
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final item in targets) {
        await _repo.applyLocalWrite(
          buildDeleteOp(
            table: kShoppingTable,
            id: item.id!,
            nowMillis: DateTime.now().millisecondsSinceEpoch,
            seq: _nextSeq(),
          ),
        );
      }
      await _reload();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyError(e, 'No se pudo quitar'))),
      );
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          // Con acción Flutter la deja fija; que se vaya sola.
          persist: false,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _restore(targets),
          ),
        ),
      );
  }

  /// Vuelve a añadir productos quitados (con ids locales nuevos).
  Future<void> _restore(List<ShoppingListItem> items) async {
    try {
      for (final item in items) {
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        final localId = newLocalId(nowMillis: nowMillis, seq: _nextSeq());
        await _repo.applyLocalWrite(
          buildInsertOp(
            table: kShoppingTable,
            id: localId,
            payload: {...item.toCacheMap(), 'id': localId},
            nowMillis: nowMillis,
            seq: _nextSeq(),
          ),
        );
      }
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, 'No se pudo deshacer'))),
      );
    }
  }

  /// Fila de producto: tocar marca/desmarca, deslizar a la izquierda marca
  /// como comprado, − / + cambia la cantidad y mantener pulsado abre las
  /// acciones (cambiar foto, borrar).
  Widget _buildRow(ShoppingListItem item) {
    final done = item.checked;
    final photo = FoodImage(
      name: item.name,
      itemType: item.itemType,
      // Sin fotos, el icono del producto. Las fotos de banco salen al azar:
      // mejor el icono hasta que llegue la del envase.
      imageUrl: !_view.showPhotos || isStockPhoto(item.imageUrl)
          ? null
          : item.imageUrl,
      forceIllustration: !_view.showPhotos,
      size: 42,
      radius: 10,
    );
    return SwipeAction(
      key: ValueKey(item.id ?? item.name + item.hashCode.toString()),
      toLeft: done
          ? null
          : SwipeSide(
              icon: Icons.check_rounded,
              color: AppColors.done,
              label: 'Al carrito',
              onTrigger: () => _toggleChecked(item, true),
            ),
      child: ShoppingItemTile(
        name: shoppingCleanName(item.name),
        checked: done,
        quantityLabel: shoppingQtyLabel(item.quantity, item.unit),
        quantity: item.quantity,
        unit: item.unit,
        onQuantityChanged: (q) => _setQuantity(item, q),
        subtitle: item.source == 'auto' ? 'Del plan de la semana' : null,
        onToggle: () => _toggleChecked(item, !done),
        onLongPress: () => _openItemActions(item),
        // Tocar la foto permite cambiarla (cámara, galería o súper).
        leading: _view.showPhotos
            ? Semantics(
                button: true,
                label: 'Cambiar foto',
                child: GestureDetector(
                  onTap: () => _openItemActions(item),
                  child: photo,
                ),
              )
            : photo,
      ),
    );
  }

  Widget _emptyState() {
    return EmptyState(
      image: 'assets/images/vacio_compra.png',
      title: 'Tu lista está vacía',
      message: 'Escribe arriba lo que necesitas o trae lo del plan.',
      actionLabel: 'Desde el plan',
      actionIcon: Icons.event_note_rounded,
      onAction: _generating ? null : _generarDesdePlan,
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
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

    const carro = Image(
      image: AssetImage('assets/images/vacio_compra.png'),
      width: 72,
      height: 72,
    );
    final miau = animar ? ScaleTransition(scale: _scale, child: carro) : carro;

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
              children: [
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
