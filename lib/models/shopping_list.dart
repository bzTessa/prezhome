/// Una lista de la compra del hogar (tabla public.shopping_lists, migración
/// 0045). Permite tener VARIAS listas (p. ej. una por súper). Los artículos
/// (ShoppingListItem) apuntan a una lista por su `listId`; `listId` null se
/// trata como la "Lista principal".
class ShoppingList {
  final String? id;
  final String homeId;
  final String name;

  /// Color (hex u otra convención de la app) e icono (nombre lógico) para
  /// decorar la lista. Opcionales.
  final String? color;
  final String? icon;
  final DateTime? createdAt;

  ShoppingList({
    this.id,
    required this.homeId,
    required this.name,
    this.color,
    this.icon,
    this.createdAt,
  });

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    // Parseo tolerante a nulls (algunas consultas pueden no traer todo).
    return ShoppingList(
      id: map['id'] as String?,
      homeId: (map['home_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: _parseDate(map['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  // No incluimos id ni created_at: los pone la base de datos.
  Map<String, dynamic> toInsertMap() {
    return {
      'home_id': homeId,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }
}
