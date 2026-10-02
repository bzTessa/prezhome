import '../utils/measure_format.dart';

class Ingredient {
  final String? id;
  final String name;
  final double? quantity;
  final String? unit;
  final int position;

  Ingredient({
    this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.position = 0,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      position: (map['position'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap({
    required String recipeId,
    required String homeId,
  }) {
    return {
      'recipe_id': recipeId,
      'home_id': homeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'position': position,
    };
  }

  /// Texto legible: "2 unidades Cebolla" o "Sal al gusto".
  ///
  /// Delega el formateo de cantidad+unidad en [formatQuantityUnit] para que el
  /// plural concuerde ("2 unidades" y no "2 unidad") aunque la IA devuelva la
  /// unidad en singular.
  String get display {
    final measure = formatQuantityUnit(quantity, unit);
    if (measure.isEmpty) return name;
    return '$measure $name';
  }
}
