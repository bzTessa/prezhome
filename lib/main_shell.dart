import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/dashboard_prefs.dart';
import 'tabs/home_tab.dart';
import 'tabs/comidas_tab.dart';
import 'tabs/despensa_tab.dart';
import 'household_screen.dart';
import 'tasks_screen.dart';
import 'theme/app_theme.dart';

/// Identidad semántica de cada pestaña del shell. Se usa para calcular los
/// índices por identidad (no por número) de forma que la navegación siga
/// funcionando aunque alguna pestaña opcional desaparezca.
enum TabId { comidas, despensa, inicio, tareas, hogar }

/// Orden FIJO de pestañas candidatas (Comidas, Despensa, Inicio, Tareas,
/// Hogar) filtrado por los módulos activados. Solo Tareas es condicional (se
/// incluye si el módulo Tareas está activo). Función pura y testeable: el shell
/// la usa para construir páginas, destinos e índices desde una ÚNICA fuente de
/// verdad, así children del IndexedStack y destinos del NavigationBar nunca se
/// desincronizan.
///
/// Nota Paso 5: batch_prep_timeline_screen añadirá aquí su TabId condicionado a
/// HomeModule.batchCooking.
List<TabId> computeVisibleTabIds(DashboardPrefs prefs) {
  return [
    TabId.comidas,
    TabId.despensa,
    TabId.inicio,
    if (prefs.isModuleEnabled(HomeModule.tasks)) TabId.tareas,
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
/// Secciones agrupadas por momento de uso: Comidas (plan, recetas y diario) ·
/// Despensa (inventario y compra) · Inicio (resumen del día, centro) · Tareas ·
/// Hogar (miembros, economía, perfil y ajustes).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

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

  @override
  void initState() {
    super.initState();
    // Arrancar en Inicio con el índice calculado por identidad semántica.
    _index = _indexOf(TabId.inicio);
    _loadPrefs();
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
  /// (Comidas, Despensa, Inicio, Tareas, Hogar). Solo Tareas es condicional:
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
            label: 'Comidas',
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(
        index: _index,
        children: [for (final t in _tabs) t.page],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.wood,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          height: 68,
          destinations: [for (final t in _tabs) t.destination],
        ),
      ),
    );
  }
}
