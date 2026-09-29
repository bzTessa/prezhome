import 'package:flutter/material.dart';

import 'tabs/home_tab.dart';
import 'tabs/meals_tab.dart';
import 'household_screen.dart';
import 'widgets/coming_soon.dart';
import 'widgets/miau_character.dart';
import 'theme/app_theme.dart';

/// Estructura principal de la app con barra de navegación inferior.
/// Secciones: Inicio (calendario/dashboard) · Comidas · Tareas · Economía · Hogar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    HomeTab(),
    MealsTab(),
    _TasksTab(),
    _EconomyTab(),
    HouseholdScreen(),
  ];

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
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Comidas',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tareas',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Economía',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_work_outlined),
              selectedIcon: Icon(Icons.home_work),
              label: 'Hogar',
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Tareas')),
      body: const ComingSoon(
        title: 'Tareas del hogar',
        message:
            'Pronto podréis repartir las tareas de casa de forma cooperativa, '
            'con un sistema de puntos para motivaros.',
      ),
    );
  }
}

class _EconomyTab extends StatelessWidget {
  const _EconomyTab();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Economía')),
      body: const ComingSoon(
        title: 'Economía del hogar',
        message:
            'Pronto podrás escanear tickets de la compra, controlar el gasto '
            'del mes y que los precios actualicen tus recetas.',
        mood: MiauMood.curious,
      ),
    );
  }
}
