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

/// Preferencias del dashboard de Inicio de un usuario: orden y visibilidad de
/// las tarjetas, y accesos rápidos elegidos. Se serializa a/desde el JSON de
/// profiles.dashboard_prefs. Tolerante a datos ausentes o antiguos.
class DashboardPrefs {
  /// Orden de las tarjetas (todas las conocidas, incluidas las ocultas).
  final List<DashboardCard> order;

  /// Ids de tarjetas ocultas.
  final Set<DashboardCard> hidden;

  /// Accesos rápidos elegidos (en orden). Vacío = usar los por defecto.
  final List<QuickAction> quick;

  const DashboardPrefs({
    required this.order,
    required this.hidden,
    required this.quick,
  });

  /// Preferencias por defecto: todas las tarjetas visibles en el orden clásico
  /// y unos accesos rápidos sensatos.
  factory DashboardPrefs.defaults() => const DashboardPrefs(
    order: DashboardCard.values,
    hidden: {},
    quick: [
      QuickAction.addInventory,
      QuickAction.shopping,
      QuickAction.scanTicket,
    ],
  );

  /// Tarjetas visibles en su orden (las no ocultas).
  List<DashboardCard> get visibleCards =>
      order.where((c) => !hidden.contains(c)).toList();

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

    return DashboardPrefs(
      order: order,
      hidden: hidden,
      quick: quick.isEmpty ? DashboardPrefs.defaults().quick : quick,
    );
  }

  Map<String, dynamic> toJson() => {
    'cards': order.map((c) => c.id).toList(),
    'hidden': hidden.map((c) => c.id).toList(),
    'quick': quick.map((q) => q.id).toList(),
  };

  DashboardPrefs copyWith({
    List<DashboardCard>? order,
    Set<DashboardCard>? hidden,
    List<QuickAction>? quick,
  }) => DashboardPrefs(
    order: order ?? this.order,
    hidden: hidden ?? this.hidden,
    quick: quick ?? this.quick,
  );
}
