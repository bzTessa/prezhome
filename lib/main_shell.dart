import 'package:flutter/material.dart';

import 'tabs/home_tab.dart';
import 'tabs/comidas_tab.dart';
import 'tabs/despensa_tab.dart';
import 'household_screen.dart';
import 'tasks_screen.dart';
import 'theme/app_theme.dart';

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
  static const _homeIndex = 2; // Inicio (centro)
  int _index = _homeIndex; // arranca en Inicio

  // Clave para refrescar la pestaña Inicio al volver a ella sin reconstruir
  // las demás pestañas del IndexedStack.
  final GlobalKey<HomeTabState> _homeKey = GlobalKey<HomeTabState>();

  static const _despensaIndex = 1; // Despensa (Inventario/Compra)

  late final List<Widget> _pages = [
    const ComidasTab(),
    const DespensaTab(),
    HomeTab(key: _homeKey, onNavigateToDespensa: _goToDespensa),
    const TasksScreen(),
    const HouseholdScreen(),
  ];

  void _onDestinationSelected(int i) {
    setState(() => _index = i);
    // Al volver a Inicio, refrescar la vista activa para reflejar cambios
    // (p. ej. un plan recién generado) sin recargar toda la app.
    if (i == _homeIndex) {
      _homeKey.currentState?.refreshActiveView();
    }
  }

  /// Cambia la pestaña activa. Lo usan las tarjetas de Inicio que son una vista
  /// de estado de otra sección (p. ej. 'Caducidades' lleva a Despensa) para
  /// aterrizar donde esa función vive de verdad, en lugar de abrir una copia
  /// suelta a pantalla completa.
  void goToTab(int index) {
    setState(() => _index = index);
  }

  /// Lleva a la pestaña Despensa (sub-tab Inventario por defecto, que es el
  /// sitio real del inventario). Se inyecta a HomeTab para la tarjeta de
  /// caducidades.
  void _goToDespensa() => goToTab(_despensaIndex);

  /// Refresca la vista activa de la pestaña Inicio. Lo usa HomeSessionScreen
  /// tras cerrarse el cuestionario automatico, para que el dashboard refleje el
  /// objetivo de calorias recien calculado sin tener que cambiar de pestana.
  void refreshHome() {
    _homeKey.currentState?.refreshActiveView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(index: _index, children: _pages),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Comidas',
            ),
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined),
              selectedIcon: Icon(Icons.kitchen),
              label: 'Despensa',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tareas',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Hogar',
            ),
          ],
        ),
      ),
    );
  }
}
