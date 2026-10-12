/// Una categoría/sección personalizada de la lista de la compra del hogar
/// (tabla public.shopping_categories, migración 0045). Define las secciones en
/// las que se agrupan los artículos (Frutas y Verduras, Condimentos...), con un
/// orden (`position`). Los artículos apuntan a una categoría por su
/// `categoryId`; `categoryId` null se trata como "Sin categorizar".
class ShoppingCategory {
  final String? id;
  final String homeId;
  final String name;

  /// Orden de la categoría dentro de la lista (menor = más arriba). Null = al
  /// final.
  final int? position;
  final String? color;
  final String? icon;
  final DateTime? createdAt;

  ShoppingCategory({
    this.id,
    required this.homeId,
    required this.name,
    this.position,
    this.color,
    this.icon,
    this.createdAt,
  });

  factory ShoppingCategory.fromMap(Map<String, dynamic> map) {
    // Parseo tolerante a nulls.
    return ShoppingCategory(
      id: map['id'] as String?,
      homeId: (map['home_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      position: (map['position'] as num?)?.toInt(),
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
      'position': position,
      'color': color,
      'icon': icon,
    };
  }

  /// Copia con cambios puntuales (p. ej. al renombrar o reordenar).
  ShoppingCategory copyWith({String? name, int? position}) {
    return ShoppingCategory(
      id: id,
      homeId: homeId,
      name: name ?? this.name,
      position: position ?? this.position,
      color: color,
      icon: icon,
      createdAt: createdAt,
    );
  }
}
