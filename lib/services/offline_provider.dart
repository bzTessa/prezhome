/// Punto único de acceso a los [OfflineRepository] de la app (Paso 7).
///
/// Las pantallas de la lista de la compra y de la despensa se instancian DOS
/// veces (embebidas en el `IndexedStack` del shell y como ruta propia). Para
/// que ambas instancias compartan EXACTAMENTE la misma caché y la misma cola
/// en memoria (y no se pisen entre sí), los repositorios viven aquí como
/// SINGLETONS perezosos, no dentro del estado de cada pantalla.
///
/// Diseño:
/// - Un solo [FileLocalStore] en disco para toda la app (en producción) o el
///   [LocalStore] que se inyecte (en tests).
/// - Un solo [SupabaseRemoteSender] (o el [RemoteSender] inyectado).
/// - Un [OfflineRepository] por tabla: `shopping_list_items` e
///   `inventory_items`, que comparten store y sender y, por tanto, la MISMA
///   cola namespaced por hogar.
///
/// El `home_id` real lo resuelve el `SupabaseRemoteSender` al hablar con la
/// red; aquí usamos una clave de hogar LOCAL para namespacear la caché/cola en
/// disco. Al cerrar sesión o cambiar de hogar, [clearForLogout]/[switchHome]
/// limpian ambos repositorios para que la caché nunca mezcle hogares
/// (ver steering de seguridad).
library;

import 'file_local_store.dart';
import 'local_store.dart';
import 'offline_repository.dart';
import 'supabase_remote_sender.dart';

/// Tabla de la lista de la compra en Supabase.
const String kShoppingTable = 'shopping_list_items';

/// Tabla del inventario (despensa/nevera) en Supabase.
const String kInventoryTable = 'inventory_items';

/// Clave de hogar por defecto para namespacear la caché local ANTES de conocer
/// el `home_id` real. Es solo una etiqueta de partición en disco; la seguridad
/// real la da la RLS de Supabase. Al resolver el hogar de verdad se llama a
/// [OfflineProvider.switchHome] para separar la caché por hogar.
const String kDefaultLocalHome = 'local';

/// Contenedor perezoso de los repositorios offline-first compartidos.
class OfflineProvider {
  OfflineProvider._();

  static final OfflineProvider instance = OfflineProvider._();

  LocalStore? _store;
  RemoteSender? _sender;
  OfflineRepository? _shopping;
  OfflineRepository? _inventory;

  /// Hogar local activo (etiqueta de partición de la caché en disco).
  String _homeId = kDefaultLocalHome;

  /// Permite inyectar un [LocalStore] y un [RemoteSender] FALSOS en tests. Debe
  /// llamarse ANTES de usar los repositorios. En producción no se llama y se
  /// usan [FileLocalStore] + [SupabaseRemoteSender] por defecto.
  void configureForTest({
    required LocalStore store,
    required RemoteSender sender,
    String homeId = kDefaultLocalHome,
  }) {
    _store = store;
    _sender = sender;
    _homeId = homeId;
    _shopping = null;
    _inventory = null;
  }

  LocalStore get _effectiveStore => _store ??= FileLocalStore();

  RemoteSender get _effectiveSender => _sender ??= SupabaseRemoteSender();

  /// Repositorio de la lista de la compra (creación perezosa).
  OfflineRepository get shopping => _shopping ??= OfflineRepository(
    table: kShoppingTable,
    store: _effectiveStore,
    sender: _effectiveSender,
    homeId: _homeId,
  );

  /// Repositorio del inventario (creación perezosa).
  OfflineRepository get inventory => _inventory ??= OfflineRepository(
    table: kInventoryTable,
    store: _effectiveStore,
    sender: _effectiveSender,
    homeId: _homeId,
  );

  /// Limpia la caché y la cola de AMBOS repositorios. Se invoca al CERRAR
  /// SESIÓN para que la caché local no arrastre datos de otro hogar.
  Future<void> clearForLogout() async {
    await shopping.clearForLogout();
    await inventory.clearForLogout();
  }

  /// Cambia el hogar activo: separa (borra) la caché/cola del hogar anterior en
  /// ambos repositorios y pasa a operar sobre [newHomeId] con estado limpio.
  Future<void> switchHome(String newHomeId) async {
    if (newHomeId == _homeId) return;
    _homeId = newHomeId;
    await shopping.switchHome(newHomeId);
    await inventory.switchHome(newHomeId);
  }
}
