import 'package:flutter/material.dart';
import 'package:prez_ui/prez_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/l10n.dart';
import 'models/dashboard_prefs.dart';
import 'models/inventory_item.dart';
import 'services/connection_status.dart';
import 'services/offline_provider.dart';
import 'services/proactive_suggestions_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/comidas_tab.dart';
import 'tabs/despensa_tab.dart';
import 'shopping_list_screen.dart';
import 'tasks_screen.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'widgets/offline_banner.dart';
import 'widgets/proactive_suggestions_banner.dart';
import 'services/onboarding_applier.dart';

/// Identidad semántica de cada pestaña del shell. Se usa para calcular los
/// índices por identidad (no por número) de forma que la navegación siga
/// funcionando aunque alguna pestaña opcional desaparezca.
enum TabId { comidas, compra, despensa, inicio, tareas }

/// Orden FIJO de pestañas candidatas (Hoy, Comida, Compra, Despensa, Tareas)
/// (todas fijas). La compra tiene pestaña propia (es lo
/// que más se usa); los ajustes del hogar se abren desde el perfil en Hoy.
///
/// Nota Paso 5: batch_prep_timeline_screen añadirá aquí su TabId condicionado a
/// HomeModule.batchCooking.
List<TabId> computeVisibleTabIds(DashboardPrefs prefs) {
  return [
    TabId.inicio,
    TabId.comidas,
    TabId.compra,
    TabId.despensa,
    // Tareas siempre visible: al ocultarse con el módulo parecía que se había
    // borrado la sección.
    TabId.tareas,
  ];
}

/// Descriptor de una pestaña: su identidad semántica, el widget que renderiza
/// (página del IndexedStack) y su pestaña en la barra de navegación. Construir
/// las páginas y las pestañas desde la MISMA lista garantiza que children del
/// IndexedStack y pestañas de la FloatingNavBar estén siempre alineados en
/// orden y longitud.
class _TabDescriptor {
  final TabId id;
  final Widget page;
  final IconData icon;
  final IconData selectedIcon;
  const _TabDescriptor({
    required this.id,
    required this.page,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Estructura principal de la app con barra de navegación inferior.
/// Secciones agrupadas por momento de uso: Hoy (resumen del día) · Comida
/// (plan, recetas y diario) · Tareas · Despensa · Hogar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// El shell vivo (el último montado), para que cualquier flujo que necesite
  /// avisarle (p. ej. el wizard de perfil, que puede cambiar los módulos)
  /// lo alcance aunque esté en otra ruta. No es una GlobalKey: al entrar o
  /// salir de un hogar se monta un shell nuevo mientras el viejo sigue en su
  /// ruta, y una misma GlobalKey en los dos rompía la app (pantalla roja
  /// '_dependents.isEmpty').
  static MainShellState? current;

  /// Recarga las prefs del shell vivo y reconstruye la barra de navegación para
  /// reflejar un cambio de módulos. No hace nada si el shell no está montado
  /// (p. ej. durante tests que no usan el shell). Lo llaman las entradas al
  /// wizard que no pasan por refreshHome() (aviso de calorías en Inicio y la
  /// pantalla de perfil nutricional).
  static void reloadModules() => current?.reloadModules();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  final SupabaseClient _client = Supabase.instance.client;

  // Preferencias del hogar: deciden qué pestañas/secciones son visibles. Por
  // defecto todos los módulos activados (compatibilidad hacia atrás).
  DashboardPrefs _prefs = DashboardPrefs.defaults();

  // Pestañas construidas dinámicamente a partir de _prefs. _index indexa esta
  // lista (y por tanto el IndexedStack y la FloatingNavBar, que se construyen
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
    MainShell.current = this;
    // Arrancar en Inicio con el índice calculado por identidad semántica.
    _index = _indexOf(TabId.inicio);
    _loadPrefs();
    _loadSuggestions();
    ConnectionStatus.instance.start();
  }

  @override
  void dispose() {
    if (identical(MainShell.current, this)) MainShell.current = null;
    super.dispose();
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
      // Primero, si hay respuestas del cuestionario inicial sin aplicar (recién
      // creada la cuenta y el hogar), se guardan en el perfil.
      final applied = await OnboardingApplier.applyIfPending(_client);
      if (applied) _homeKey.currentState?.refreshActiveView();
      if (applied && OnboardingApplier.weekBuilt && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tu semana está lista: comidas, cenas y lista de la compra',
            ),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => goToTab(_indexOf(TabId.comidas)),
            ),
          ),
        );
      }
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
  /// (Hoy, Comida, Compra, Despensa, Tareas). Solo Tareas es condicional:
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
          icon: Icons.restaurant_menu_outlined,
          selectedIcon: Icons.restaurant_menu,
        );
      case TabId.compra:
        return _TabDescriptor(
          id: id,
          page: ColoredBox(
            color: AppColors.cream,
            child: SafeArea(
              bottom: false,
              child: ShoppingListScreen(embedded: true),
            ),
          ),
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
        );
      case TabId.despensa:
        return _TabDescriptor(
          id: id,
          page: const DespensaTab(),
          icon: Icons.kitchen_outlined,
          selectedIcon: Icons.kitchen,
        );
      case TabId.inicio:
        return _TabDescriptor(
          id: id,
          page: HomeTab(
            key: _homeKey,
            onNavigateToDespensa: _goToDespensa,
            onNavigateToShopping: () => goToTab(_indexOf(TabId.compra)),
            onNavigateToTasks: () {
              final i = _indexOf(TabId.tareas);
              if (i >= 0) goToTab(i);
            },
            onNavigateToPlan: () => goToTab(_indexOf(TabId.comidas)),
          ),
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        );
      case TabId.tareas:
        return _TabDescriptor(
          id: id,
          page: const TasksScreen(),
          icon: Icons.check_circle_outline,
          selectedIcon: Icons.check_circle,
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
  /// opción realista y honesta es llevar a la pestaña Comida, donde vive el
  /// plan y el acceso al "Modo cocina" (meal_plan_screen abre
  /// BatchPrepTimelineScreen). Desde ahí la usuaria aprovecha lo que caduca en
  /// su próximo Batch Cooking. No inventamos un atajo que no existe.
  void _onSuggestionsAction() {
    setState(() => _suggestionsDismissed = true);
    goToTab(_indexOf(TabId.comidas));
  }

  @override
  Widget build(BuildContext context) {
    // En Inicio no: la ficha "Por caducar" ya lo cuenta.
    final showBanner =
        _suggestions.isNotEmpty &&
        !_suggestionsDismissed &&
        _index != _indexOf(TabId.inicio);
    // Ordenador (web): menú lateral y contenido centrado en vez de la barra
    // inferior de móvil.
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final navItems = [
      for (final t in _tabs)
        FloatingNavItem(
          icon: t.icon,
          selectedIcon: t.selectedIcon,
          label: context.l.tabLabel(t.id.name),
        ),
    ];
    // Avisos ARRIBA (servidor caído / incidencia y Asistente Proactivo) +
    // IndexedStack abajo. El IndexedStack conserva su index y children
    // intactos; la barra de navegación no se toca.
    final body = ListenableBuilder(
      listenable: Listenable.merge([
        ConnectionStatus.instance.online,
        ConnectionStatus.instance.notice,
      ]),
      builder: (context, _) {
        final online = ConnectionStatus.instance.online.value;
        final notice = ConnectionStatus.instance.notice.value;
        final showStatus = !online || notice != null;
        final showTop = showStatus || showBanner;
        return Column(
          children: [
            if (showTop)
              // SafeArea(bottom:false) para que los avisos no se metan bajo
              // la barra de estado del dispositivo (notch/isla). La parte
              // inferior la gestiona la bottomNavigationBar.
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (showStatus)
                      OfflineBanner(online: online, notice: notice),
                    if (showBanner)
                      ProactiveSuggestionsBanner(
                        suggestions: _suggestions,
                        onAction: _onSuggestionsAction,
                        onDismiss: () =>
                            setState(() => _suggestionsDismissed = true),
                      ),
                  ],
                ),
              ),
            Expanded(
              // Con avisos arriba, la barra de estado ya está cubierta: las
              // pestañas no deben volver a dejar su hueco.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: showTop,
                child: IndexedStack(
                  index: _index,
                  children: [for (final t in _tabs) t.page],
                ),
              ),
            ),
          ],
        );
      },
    );
    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Row(
          children: [
            _SideNav(
              items: navItems,
              selectedIndex: _index,
              onSelected: _onDestinationSelected,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: body,
      // Barra flotante compartida (packages/prez_ui): píldora con la pestaña
      // activa expandida (icono + texto) y las demás solo con icono.
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FloatingNavBar(
          items: navItems,
          selectedIndex: _index,
          onSelected: _onDestinationSelected,
          // Píldora con trazo y sombra dura; la pestaña activa se desliza
          // con muelle. Sin translucidez: el contenido no pasa por debajo.
          backgroundColor: AppColors.card,
          border: Border.all(color: AppColors.stroke, width: 2),
          indicatorColor: AppColors.wood,
          selectedColor: AppColors.ink,
          unselectedColor: AppColors.inkMuted,
          shadow: AppElevation.level1,
          duration: AppMotion.slow,
          curve: AppMotion.springCurve(AppMotion.fluidDefault),
        ),
      ),
    );
  }
}

/// Menú lateral de la versión de ordenador: logo arriba y las mismas
/// pestañas que la barra inferior del móvil.
class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.stroke, width: 2)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/brand/app_icon.png',
                      width: 40,
                      height: 40,
                      cacheWidth: 120,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'PrezHome',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SideNavTile(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  const _SideNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.inkMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.wood : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon ?? item.icon : item.icon,
                  color: color,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
