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
  String get display {
    final parts = <String>[];
    if (quantity != null) {
      final q = quantity! % 1 == 0
          ? quantity!.toStringAsFixed(0)
          : quantity!.toString();
      parts.add(q);
    }
    if (unit != null && unit!.isNotEmpty) parts.add(unit!);
    parts.add(name);
    return parts.join(' ');
  }
}
