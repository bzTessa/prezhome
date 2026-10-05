import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/dashboard_prefs.dart';
import 'models/inventory_item.dart';
import 'services/offline_provider.dart';
import 'services/proactive_suggestions_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/comidas_tab.dart';
import 'tabs/despensa_tab.dart';
import 'household_screen.dart';
import 'tasks_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/proactive_suggestions_banner.dart';

/// Identidad semántica de cada pestaña del shell. Se usa para calcular los
/// índices por identidad (no por número) de forma que la navegación siga
/// funcionando aunque alguna pestaña opcional desaparezca.
enum TabId { comidas, despensa, inicio, tareas, hogar }

/// Orden FIJO de pestañas candidatas (Hoy, Meal Prep, Tareas, Despensa, Hogar)
/// filtrado por los módulos activados. Las tres primeras son las secciones de
/// uso diario y quedan agrupadas al principio de la navegación; Despensa y
/// Hogar conservan sus flujos existentes.
///
/// Nota Paso 5: batch_prep_timeline_screen añadirá aquí su TabId condicionado a
/// HomeModule.batchCooking.
List<TabId> computeVisibleTabIds(DashboardPrefs prefs) {
  return [
    TabId.inicio,
    if (prefs.isModuleEnabled(HomeModule.tasks)) TabId.tareas,
    TabId.comidas,
    TabId.despensa,
    TabId.hogar,
  ];
}

/// Descriptor de una pestaña: su identidad semántica, el widget que renderiza
/// (página del IndexedStack) y su destino en la barra de navegación. Construir
/// las páginas y los destinos desde la MISMA lista garantiza que children del
/// IndexedStack y destinos del NavigationBar estén siempre alineados en orden
/// y longitud.
class _TabDescriptor {
  final TabId id;
  final Widget page;
  final NavigationDestination destination;
  const _TabDescriptor({
    required this.id,
    required this.page,
    required this.destination,
  });
}

/// Estructura principal de la app con barra de navegación inferior.
/// Secciones agrupadas por momento de uso: Hoy (resumen del día) · Meal Prep
/// (plan, recetas y diario) · Tareas · Despensa · Hogar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Clave global del shell vivo. HomeSessionScreen construye el shell con esta
  /// clave, de modo que cualquier flujo que necesite avisar al shell (p. ej. el
  /// wizard de perfil, que puede cambiar los módulos activados) pueda alcanzar
  /// su State sin acoplarse a la posición en el árbol de widgets. Es necesario
  /// porque las rutas que empuja Navigator.push (como el wizard abierto desde
  /// la pantalla de perfil) son hermanas del shell bajo el Navigator raíz, no
  /// descendientes, así que findAncestorStateOfType no las alcanzaría.
  static final GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

  /// Recarga las prefs del shell vivo y reconstruye la barra de navegación para
  /// reflejar un cambio de módulos. No hace nada si el shell no está montado
  /// (p. ej. durante tests que no usan el shell). Lo llaman las entradas al
  /// wizard que no pasan por refreshHome() (aviso de calorías en Inicio y la
  /// pantalla de perfil nutricional).
  static void reloadModules() => shellKey.currentState?.reloadModules();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  final SupabaseClient _client = Supabase.instance.client;

  // Preferencias del hogar: deciden qué pestañas/secciones son visibles. Por
  // defecto todos los módulos activados (compatibilidad hacia atrás).
  DashboardPrefs _prefs = DashboardPrefs.defaults();

  // Pestañas construidas dinámicamente a partir de _prefs. _index indexa esta
  // lista (y por tanto el IndexedStack y el NavigationBar, que se construyen
  // desde ella).
  late List<_TabDescriptor> _tabs = _buildTabs();

  int _index = 0; // se fija al índice de Inicio en initState

  // Clave para refrescar la pestaña Inicio al volver a ella sin reconstruir
  // las demás pestañas del IndexedStack.
  final GlobalKey<HomeTabState> _homeKey = GlobalKey<HomeTabState>();

  // Asistente Proactivo (Paso 8, motor LOCAL sin IA): sugerencias de alimentos
  // a punto de caducar (<= 2 días) para aprovechar en el próximo Batch Cooking.
  // Se calculan best-effort desde la caché del inventario (instantáneo) y se
  // muestran en un banner descartable sobre el body del IndexedStack.
  List<ExpiringSuggestion> _suggestions = const [];

  // La usuaria puede descartar el banner; se vuelve a evaluar en la próxima
  // recarga del shell.
  bool _suggestionsDismissed = false;

  @override
  void initState() {
    super.initState();
    // Arrancar en Inicio con el índice calculado por identidad semántica.
    _index = _indexOf(TabId.inicio);
    _loadPrefs();
    _loadSuggestions();
  }

  /// Carga best-effort las sugerencias de caducidad del Asistente Proactivo.
  ///
  /// Lee el inventario desde la CACHÉ local (instantáneo, offline-first del
  /// Paso 7), lo mapea a [ProactiveStockItem] (isFood = comida y no especia,
  /// que no caducan de forma relevante) y llama al motor puro
  /// [buildExpiringSuggestions]. Refresca en segundo plano sin bloquear. Si
  /// algo falla, simplemente no se muestra el banner.
  Future<void> _loadSuggestions() async {
    final repo = OfflineProvider.instance.inventory;
    try {
      final rows = await repo.readCached();
      _applySuggestionsFromRows(rows);
      // Refresco best-effort: si hay red, actualizamos con el estado remoto.
      repo.refreshFromRemote().then(_applySuggestionsFromRows).catchError((_) {
        // Sin red: nos quedamos con lo calculado desde la caché.
      });
    } catch (_) {
      // Sin caché todavía: no mostramos banner.
    }
  }

  /// Mapea filas crudas del inventario a sugerencias de caducidad y las guarda
  /// en estado. setState con cuerpo de bloque (nunca arrow con Future).
  void _applySuggestionsFromRows(List<Map<String, dynamic>> rows) {
    final stock = rows.map((row) {
      final item = InventoryItem.fromMap(row);
      return ProactiveStockItem(
        name: item.name,
        daysUntilExpiry: item.daysUntilExpiry,
        isFood: item.itemType == 'comida' && item.category != 'Especias',
      );
    }).toList();
    final suggestions = buildExpiringSuggestions(stock);
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
    });
  }

  /// Carga las preferencias del hogar (profiles.dashboard_prefs) para el
  /// usuario actual y reconstruye la navegación. Mismo patrón tolerante que
  /// HomeTab._loadPrefs: si no hay fila o es ilegible, se usan los defaults.
  Future<void> _loadPrefs() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final row = await _client
          .from('profiles')
          .select('dashboard_prefs')
          .eq('id', user.id)
          .maybeSingle();
      final raw = row?['dashboard_prefs'];
      final prefs = raw is Map
          ? DashboardPrefs.fromJson(Map<String, dynamic>.from(raw))
          : DashboardPrefs.defaults();
      if (mounted) {
        setState(() {
          _prefs = prefs;
          _rebuildTabs();
        });
      }
    } catch (e) {
      debugPrint('MainShell._loadPrefs error: $e');
    }
  }

  /// Construye la lista ordenada de pestañas candidatas en un orden FIJO
  /// (Hoy, Tareas, Meal Prep, Despensa, Hogar). Solo Tareas es condicional:
  /// se incluye únicamente si el módulo está activado. Páginas y destinos
  /// salen de aquí para no desincronizarse nunca.
  ///
  /// Nota Paso 5: cuando llegue batch_prep_timeline_screen, su entrada de
  /// navegación se añadirá aquí condicionada a
  /// _prefs.isModuleEnabled(HomeModule.batchCooking). El flag ya se persiste
  /// hoy aunque todavía no haya pieza visible que gobernar.
  List<_TabDescriptor> _buildTabs() {
    return [for (final id in computeVisibleTabIds(_prefs)) _descriptorFor(id)];
  }

  /// Página + destino de cada pestaña por su identidad semántica. HomeTab
  /// conserva su key y el callback a Despensa calculado por identidad.
  _TabDescriptor _descriptorFor(TabId id) {
    switch (id) {
      case TabId.comidas:
        return _TabDescriptor(
          id: id,
          page: const ComidasTab(),
          destination: const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Meal Prep',
          ),
        );
      case TabId.despensa:
        return _TabDescriptor(
          id: id,
          page: const DespensaTab(),
          destination: const NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Despensa',
          ),
        );
      case TabId.inicio:
        return _TabDescriptor(
          id: id,
          page: HomeTab(key: _homeKey, onNavigateToDespensa: _goToDespensa),
          destination: const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Hoy',
          ),
        );
      case TabId.tareas:
        return _TabDescriptor(
          id: id,
          page: const TasksScreen(),
          destination: const NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tareas',
          ),
        );
      case TabId.hogar:
        return _TabDescriptor(
          id: id,
          page: const HouseholdScreen(),
          destination: const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Hogar',
          ),
        );
    }
  }

  /// Recomputa la lista de pestañas y CLAMPEA _index para que una pestaña que
  /// desaparece (p. ej. Tareas al desactivarse) no deje _index fuera de rango
  /// y haga crashear el IndexedStack. Debe llamarse dentro de un setState.
  void _rebuildTabs() {
    _tabs = _buildTabs();
    if (_index >= _tabs.length) {
      _index = _indexOf(TabId.inicio);
    }
  }

  /// Índice (posición en la lista construida) de una pestaña por su identidad
  /// semántica. Si la pestaña no está presente, cae en Inicio.
  int _indexOf(TabId id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i >= 0) return i;
    final home = _tabs.indexWhere((t) => t.id == TabId.inicio);
    return home >= 0 ? home : 0;
  }

  void _onDestinationSelected(int i) {
    setState(() => _index = i);
    // Al volver a Inicio, refrescar la vista activa para reflejar cambios
    // (p. ej. un plan recién generado) sin recargar toda la app. El índice de
    // Inicio se calcula por identidad, nunca se hardcodea.
    if (i == _indexOf(TabId.inicio)) {
      _homeKey.currentState?.refreshActiveView();
    }
  }

  /// Cambia la pestaña activa. Lo usan las tarjetas de Inicio que son una vista
  /// de estado de otra sección (p. ej. 'Caducidades' lleva a Despensa) para
  /// aterrizar donde esa función vive de verdad, en lugar de abrir una copia
  /// suelta a pantalla completa.
  void goToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _index = index);
  }

  /// Lleva a la pestaña Despensa (sub-tab Inventario por defecto, que es el
  /// sitio real del inventario). Se inyecta a HomeTab para la tarjeta de
  /// caducidades. El índice de Despensa se calcula por identidad semántica, así
  /// que 'Caducidades -> Despensa' sigue funcionando aunque falte Tareas.
  void _goToDespensa() => goToTab(_indexOf(TabId.despensa));

  /// Refresca la vista activa de la pestaña Inicio. Lo usa HomeSessionScreen
  /// tras cerrarse el cuestionario/wizard, para que el dashboard refleje el
  /// objetivo de calorias recien calculado sin tener que cambiar de pestana.
  ///
  /// Propagación de módulos: el wizard puede cambiar los módulos activados, lo
  /// que altera qué pestañas son visibles. Como el wizard retorna al shell
  /// pasando por este punto, aquí recargamos _prefs y reconstruimos la
  /// navegación. Una app ya en marcha vuelve a leer las prefs en la siguiente
  /// recarga del shell (p. ej. al refrescar Inicio).
  void refreshHome() {
    _loadPrefs();
    _homeKey.currentState?.refreshActiveView();
  }

  /// Recarga las prefs y reconstruye la barra de navegación. Público para que
  /// un flujo externo (onboarding/wizard) pueda forzar que el shell refleje un
  /// cambio de módulos sin recrear MainShell.
  void reloadModules() => _loadPrefs();

  /// Acción del banner del Asistente Proactivo.
  ///
  /// DECISIÓN (FEAT-003): el ingrediente que caduca NO es una receta, así que
  /// no existe una integración directa ingrediente -> receta que abrir. La
  /// opción realista y honesta es llevar a la pestaña Meal Prep, donde vive el
  /// plan y el acceso al "Modo cocina" (meal_plan_screen abre
  /// BatchPrepTimelineScreen). Desde ahí la usuaria aprovecha lo que caduca en
  /// su próximo Batch Cooking. No inventamos un atajo que no existe.
  void _onSuggestionsAction() {
    setState(() => _suggestionsDismissed = true);
    goToTab(_indexOf(TabId.comidas));
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _suggestions.isNotEmpty && !_suggestionsDismissed;
    return Scaffold(
      backgroundColor: AppColors.cream,
      // Banner descartable del Asistente Proactivo ARRIBA + IndexedStack abajo.
      // El IndexedStack conserva su index y children intactos; la barra de
      // navegación no se toca.
      body: Column(
        children: [
          if (showBanner)
            ProactiveSuggestionsBanner(
              suggestions: _suggestions,
              onAction: _onSuggestionsAction,
              onDismiss: () => setState(() => _suggestionsDismissed = true),
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [for (final t in _tabs) t.page],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          decoration: AppTheme.surfaceDecoration(
            radius: AppRadius.lg,
            elevation: 2,
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onDestinationSelected,
            destinations: [for (final t in _tabs) t.destination],
          ),
        ),
      ),
    );
  }
}
