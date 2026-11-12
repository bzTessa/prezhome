/// Plato o postre comprado ya hecho en el súper ("Comprado hecho").
class ReadyMeal {
  const ReadyMeal({
    required this.id,
    required this.name,
    this.imageUrl,
    this.calories,
    this.kind = 'main',
    this.trusted = true,
  });

  final String id;
  final String name;
  final String? imageUrl;

  /// kcal por ración, si se saben.
  final double? calories;

  /// 'main' (plato) o 'dessert' (postre).
  final String kind;

  /// Sale en "Tus preparados"; false = quitado de la lista.
  final bool trusted;

  bool get isDessert => kind == 'dessert';

  factory ReadyMeal.fromMap(Map<String, dynamic> m) => ReadyMeal(
    id: m['id'] as String,
    name: (m['name'] ?? '') as String,
    imageUrl: m['image_url'] as String?,
    calories: (m['calories'] as num?)?.toDouble(),
    kind: (m['kind'] ?? 'main') as String,
    trusted: (m['trusted'] as bool?) ?? true,
  );
}
