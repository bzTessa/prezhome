import 'package:flutter/material.dart';

/// Tarjetas que pueden aparecer en el dashboard de Inicio. El id se guarda en
/// las preferencias (profiles.dashboard_prefs); label/icon son para el editor.
enum DashboardCard {
  reminders(
    'reminders',
    'Hoy toca (recordatorios)',
    Icons.notifications_active_outlined,
  ),
  meals('meals', 'Comidas de hoy', Icons.restaurant_menu),
  expiry('expiry', 'Caducidades', Icons.schedule),
  calories('calories', 'Calorías de hoy', Icons.local_fire_department),
  tasks('tasks', 'Tareas', Icons.check_circle_outline),
  spending('spending', 'Gasto del mes', Icons.savings_outlined);

  const DashboardCard(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;

  static DashboardCard? byId(String id) {
    for (final c in DashboardCard.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Accesos rápidos que el usuario puede fijar en Inicio (fila de botones).
enum QuickAction {
  addInventory('add_inventory', 'Añadir a despensa', Icons.add_box_outlined),
  scanTicket('scan_ticket', 'Escanear ticket', Icons.receipt_long_outlined),
  shopping('shopping', 'Lista de la compra', Icons.shopping_cart_outlined),
  addRecipe('add_recipe', 'Nueva receta', Icons.menu_book_outlined),
  mealPlan('meal_plan', 'Plan semanal', Icons.calendar_today_outlined),
  diary('diary', 'Diario de calorías', Icons.local_fire_department_outlined);

  const QuickAction(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;

  static QuickAction? byId(String id) {
    for (final q in QuickAction.values) {
      if (q.id == id) return q;
    }
    return null;
  }
}

/// Módulos del hogar que se pueden activar o desactivar. Si se desactiva un
/// módulo, sus pestañas/secciones se ocultan de la navegación. El id se guarda
/// en las preferencias (profiles.dashboard_prefs); label/icon son para la UI.
enum HomeModule {
  points('points', 'Modo Puntos', Icons.emoji_events_outlined),
  tasks('tasks', 'Tareas', Icons.check_circle_outline),
  batchCooking('batch_cooking', 'Batch Cooking', Icons.restaurant);

  const HomeModule(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;

  static HomeModule? byId(String id) {
    for (final m in HomeModule.values) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// Ritmo/estilo de cocina del hogar. Selector visual en el asistente de perfil.
/// El id se guarda en las preferencias (profiles.dashboard_prefs).
enum CookingStyle {
  batch(
    'batch',
    'Batch Cooking',
    'Cocino en tandas para varios días',
    Icons.inventory_2_outlined,
  ),
  daily(
    'daily',
    'Diario',
    'Cocino cada día lo del momento',
    Icons.today_outlined,
  ),
  mixed(
    'mixed',
    'Mixto',
    'Combino tandas y cocina del día',
    Icons.sync_outlined,
  );

  const CookingStyle(this.id, this.label, this.subtitle, this.icon);
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;

  /// Estilo por defecto sensato cuando no hay preferencia guardada.
  static const CookingStyle defaultStyle = CookingStyle.daily;

  static CookingStyle? byId(String id) {
    for (final s in CookingStyle.values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Preferencias del dashboard de Inicio de un usuario: orden y visibilidad de
/// las tarjetas, accesos rápidos elegidos, módulos activados y estilo de
/// cocina. Se serializa a/desde el JSON de profiles.dashboard_prefs. Tolerante
/// a datos ausentes o antiguos.
class DashboardPrefs {
  /// Orden de las tarjetas (todas las conocidas, incluidas las ocultas).
  final List<DashboardCard> order;

  /// Ids de tarjetas ocultas.
  final Set<DashboardCard> hidden;

  /// Accesos rápidos elegidos (en orden). Vacío = usar los por defecto.
  final List<QuickAction> quick;

  /// Módulos ACTIVADOS por el usuario. Se guarda lo activado (no lo oculto):
  /// la clave ausente significa "todos activados" (compatibilidad hacia atrás)
  /// y una lista vacía explícita significa "ninguno activado".
  final Set<HomeModule> enabledModules;

  /// Estilo/ritmo de cocina elegido.
  final CookingStyle cookingStyle;

  const DashboardPrefs({
    required this.order,
    required this.hidden,
    required this.quick,
    required this.enabledModules,
    required this.cookingStyle,
  });

  /// Preferencias por defecto: todas las tarjetas visibles en el orden clásico,
  /// unos accesos rápidos sensatos, todos los módulos activados y el estilo de
  /// cocina por defecto.
  factory DashboardPrefs.defaults() => const DashboardPrefs(
    order: DashboardCard.values,
    hidden: {},
    quick: [
      QuickAction.addInventory,
      QuickAction.shopping,
      QuickAction.scanTicket,
    ],
    enabledModules: {
      HomeModule.points,
      HomeModule.tasks,
      HomeModule.batchCooking,
    },
    cookingStyle: CookingStyle.defaultStyle,
  );

  /// Tarjetas visibles en su orden (las no ocultas).
  List<DashboardCard> get visibleCards =>
      order.where((c) => !hidden.contains(c)).toList();

  /// Indica si un módulo está activado.
  bool isModuleEnabled(HomeModule m) => enabledModules.contains(m);

  factory DashboardPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DashboardPrefs.defaults();

    // Orden: ids guardados que existan, + las tarjetas nuevas que no estaban
    // (para que al añadir tarjetas en el futuro aparezcan al final, no se
    // pierdan).
    final rawOrder = (json['cards'] as List?)?.map((e) => e.toString()) ?? [];
    final order = <DashboardCard>[];
    for (final id in rawOrder) {
      final c = DashboardCard.byId(id);
      if (c != null && !order.contains(c)) order.add(c);
    }
    for (final c in DashboardCard.values) {
      if (!order.contains(c)) order.add(c);
    }

    final hidden = <DashboardCard>{};
    for (final id in (json['hidden'] as List?) ?? []) {
      final c = DashboardCard.byId(id.toString());
      if (c != null) hidden.add(c);
    }

    final quick = <QuickAction>[];
    for (final id in (json['quick'] as List?) ?? []) {
      final q = QuickAction.byId(id.toString());
      if (q != null && !quick.contains(q)) quick.add(q);
    }

    // Módulos activados: distinguir AUSENTE (datos antiguos -> todos activados)
    // de una lista vacía explícita (ninguno activado). Ids desconocidos se
    // ignoran.
    final Set<HomeModule> enabledModules;
    final rawModules = json['modules'];
    if (!json.containsKey('modules') || rawModules == null) {
      enabledModules = DashboardPrefs.defaults().enabledModules;
    } else {
      final modules = <HomeModule>{};
      for (final id in (rawModules as List?) ?? []) {
        final m = HomeModule.byId(id.toString());
        if (m != null) modules.add(m);
      }
      enabledModules = modules;
    }

    // Estilo de cocina: id conocido o, si falta/desconocido/null, el default.
    final rawStyle = json['cooking_style'];
    final cookingStyle = (rawStyle == null)
        ? CookingStyle.defaultStyle
        : (CookingStyle.byId(rawStyle.toString()) ?? CookingStyle.defaultStyle);

    return DashboardPrefs(
      order: order,
      hidden: hidden,
      quick: quick.isEmpty ? DashboardPrefs.defaults().quick : quick,
      enabledModules: enabledModules,
      cookingStyle: cookingStyle,
    );
  }

  Map<String, dynamic> toJson() => {
    'cards': order.map((c) => c.id).toList(),
    'hidden': hidden.map((c) => c.id).toList(),
    'quick': quick.map((q) => q.id).toList(),
    'modules': enabledModules.map((m) => m.id).toList(),
    'cooking_style': cookingStyle.id,
  };

  DashboardPrefs copyWith({
    List<DashboardCard>? order,
    Set<DashboardCard>? hidden,
    List<QuickAction>? quick,
    Set<HomeModule>? enabledModules,
    CookingStyle? cookingStyle,
  }) => DashboardPrefs(
    order: order ?? this.order,
    hidden: hidden ?? this.hidden,
    quick: quick ?? this.quick,
    enabledModules: enabledModules ?? this.enabledModules,
    cookingStyle: cookingStyle ?? this.cookingStyle,
  );
}
