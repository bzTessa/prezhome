import '../utils/measure_format.dart';

class ShoppingListItem {
  final String? id;
  final String homeId;
  final String name;
  final double? quantity;
  final String? unit;
  final bool checked;
  final String source; // 'manual' o 'auto'
  final DateTime? createdAt;

  ShoppingListItem({
    this.id,
    required this.homeId,
    required this.name,
    this.quantity,
    this.unit,
    this.checked = false,
    this.source = 'manual',
    this.createdAt,
  });

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    // Parseo tolerante: algunas consultas pueden no traer todas las columnas.
    // Nunca debe petar aunque falte un campo o venga nulo.
    return ShoppingListItem(
      id: map['id'] as String?,
      homeId: (map['home_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      checked: (map['checked'] as bool?) ?? false,
      source: (map['source'] ?? 'manual') as String,
      createdAt: _parseDate(map['created_at']),
    );
  }

  // Parsea la fecha de forma segura. Si viene nula o con un formato invalido
  // devolvemos null para no romper la carga de la lista.
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
      'quantity': quantity,
      'unit': unit,
      'checked': checked,
      'source': source,
    };
  }

  /// Texto legible: "2 unidades Cebolla" o "Sal".
  ///
  /// Usa [formatQuantityUnit] (el mismo helper que [Ingredient.display]) para
  /// que el plural de la unidad concuerde con la cantidad.
  String get display {
    final measure = formatQuantityUnit(quantity, unit);
    if (measure.isEmpty) return name;
    return '$measure $name';
  }
}
