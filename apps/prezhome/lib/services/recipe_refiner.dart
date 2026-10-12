import '../utils/nutrition_calc.dart';
import '../utils/practical_quantity.dart';
import 'food_facts_service.dart';

/// Un ingrediente ya refinado: nombre + cantidad PRÁCTICA + unidad.
class RefinedIngredient {
  final String name;
  final double? quantity;
  final String? unit;
  const RefinedIngredient({required this.name, this.quantity, this.unit});
}

/// Resultado de refinar una receta de la IA con Open Food Facts.
class RefinedRecipe {
  /// Ingredientes con cantidades prácticas (formatos de súper reales).
  final List<RefinedIngredient> ingredients;

  /// Nutrición recalculada por ración, o null si no se pudo con fiabilidad
  /// (en ese caso quien llama conserva la estimación original de la IA).
  final RecipeNutrition? nutrition;

  const RefinedRecipe({required this.ingredients, this.nutrition});
}

/// Refina una receta recién generada por la IA usando Open Food Facts:
///   1. Para cada ingrediente consulta OFF (afinando por el súper del hogar) y,
///      si conoce su FORMATO DE VENTA (p. ej. bote de 400 g), ajusta la
///      cantidad a algo PRÁCTICO con [makePractical]; si no, igualmente la
///      vuelve práctica con las reglas de cocina genéricas.
///   2. Con los datos nutricionales por 100 g de OFF, recalcula kcal/macros por
///      ración sumando ingredientes ([computeRecipeNutrition]). Solo devuelve
///      esa nutrición si cubre una mayoría razonable de ingredientes
///      (isReliable); si no, deja nutrition=null y se mantiene la de la IA.
///
/// Degrada con elegancia: cada consulta a OFF ya es best-effort (nunca lanza).
/// Si OFF no sabe nada de ningún ingrediente, las cantidades igualmente salen
/// más limpias por el redondeo de cocina y la nutrición queda como la de la IA.
class RecipeRefiner {
  RecipeRefiner(this._foodFacts);

  final FoodFactsService _foodFacts;

  /// [raw] son los ingredientes tal cual los da la IA: cada uno con
  /// 'name' (String), 'quantity' (num?/String?) y 'unit' (String?).
  Future<RefinedRecipe> refine({
    required List<Map<String, dynamic>> raw,
    required int servings,
    String supermarket = '',
  }) async {
    final refined = <RefinedIngredient>[];
    final nutriIngs = <NutriIngredient>[];

    for (final m in raw) {
      final name = (m['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final qty = _toDouble(m['quantity']);
      final unit = (m['unit'] as String?)?.trim();

      final facts = await _foodFacts.lookup(name, supermarket: supermarket);

      // Cantidad práctica (usa el formato de venta de OFF si es de peso).
      final packageGrams =
          (facts.found &&
              facts.packageQuantity != null &&
              facts.packageQuantity! > 0)
          ? facts.packageQuantity
          : null;
      final pq = makePractical(name, qty, unit, packageGrams: packageGrams);
      refined.add(
        RefinedIngredient(name: name, quantity: pq.quantity, unit: pq.unit),
      );

      // Aporte nutricional (si OFF lo tiene). Usamos la cantidad PRÁCTICA para
      // que la nutrición cuadre con lo que realmente aparece en la receta.
      Per100g? per;
      if (facts.found && facts.kcal100 != null) {
        per = Per100g(
          kcal: facts.kcal100!,
          protein: facts.protein100 ?? 0,
          carbs: facts.carbs100 ?? 0,
          fat: facts.fat100 ?? 0,
        );
      }
      nutriIngs.add(
        NutriIngredient(quantity: pq.quantity, unit: pq.unit, per100g: per),
      );
    }

    final computed = computeRecipeNutrition(nutriIngs, servings);
    return RefinedRecipe(
      ingredients: refined,
      nutrition: computed.isReliable ? computed : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }
}
