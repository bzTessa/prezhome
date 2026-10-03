/// Cálculo de la nutrición de una receta SUMANDO sus ingredientes, usando los
/// datos reales por 100 g de Open Food Facts, en vez de la estimación "a ojo"
/// de la IA. Lógica PURA (sin Flutter ni red) para poder testearla.
///
/// Honestidad del método: solo puede sumar de forma fiable los ingredientes
/// cuya cantidad esté en PESO (g) o VOLUMEN (ml, que aproximamos a g con
/// densidad ~1, razonable para caldos, leche, aceite...). Los ingredientes en
/// unidades contables (huevos, dientes de ajo, latas sin peso) NO se pueden
/// convertir a gramos de forma fiable y se OMITEN del cálculo. Por eso el
/// resultado incluye cuántos ingredientes se cubrieron, para que la UI pueda
/// avisar de que es aproximado.
library;

/// Aporte nutricional por 100 g de un ingrediente (de Open Food Facts).
class Per100g {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  const Per100g({
    required this.kcal,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });
}

/// Un ingrediente para el cálculo: su cantidad, unidad y (si se conoce) su
/// aporte por 100 g. Si [per100g] es null, el ingrediente no suma (sin datos).
class NutriIngredient {
  final double? quantity;
  final String? unit;
  final Per100g? per100g;
  const NutriIngredient({this.quantity, this.unit, this.per100g});
}

/// Resultado del cálculo de nutrición de una receta.
class RecipeNutrition {
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  /// Nº de ingredientes que SÍ se pudieron incluir en el cálculo.
  final int covered;

  /// Nº total de ingredientes de la receta.
  final int total;

  const RecipeNutrition({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.covered,
    required this.total,
  });

  /// true si se cubrió una mayoría razonable de ingredientes (para decidir si
  /// merece la pena ofrecer el resultado como fiable).
  bool get isReliable => total > 0 && covered >= (total * 0.6);
}

const Set<String> _gramUnits = {'g', 'gr', 'gramo', 'gramos'};
const Set<String> _mlUnits = {'ml', 'mililitro', 'mililitros'};

/// Convierte la cantidad de un ingrediente a GRAMOS, o null si no es posible
/// de forma fiable (unidades contables, "al gusto", kg/l se escalan).
double? gramsOf(double? quantity, String? unit) {
  if (quantity == null) return null;
  final u = (unit ?? '').trim().toLowerCase();
  if (_gramUnits.contains(u)) return quantity;
  if (_mlUnits.contains(u)) return quantity; // densidad ~1
  if (u == 'kg') return quantity * 1000;
  if (u == 'l' || u == 'litro' || u == 'litros') return quantity * 1000;
  return null; // unidades contables u otras: no convertible con fiabilidad
}

/// Calcula la nutrición TOTAL de la receta sumando los ingredientes con datos,
/// y la divide entre [servings] para dar el valor POR RACIÓN. [servings] debe
/// ser >= 1.
RecipeNutrition computeRecipeNutrition(
  List<NutriIngredient> ingredients,
  int servings,
) {
  final total = ingredients.length;
  var covered = 0;
  double kcal = 0, protein = 0, carbs = 0, fat = 0;

  for (final ing in ingredients) {
    final p = ing.per100g;
    if (p == null) continue;
    final grams = gramsOf(ing.quantity, ing.unit);
    if (grams == null || grams <= 0) continue;
    final factor = grams / 100.0;
    kcal += p.kcal * factor;
    protein += p.protein * factor;
    carbs += p.carbs * factor;
    fat += p.fat * factor;
    covered++;
  }

  final s = servings < 1 ? 1 : servings;
  return RecipeNutrition(
    kcal: (kcal / s).round(),
    protein: (protein / s).round(),
    carbs: (carbs / s).round(),
    fat: (fat / s).round(),
    covered: covered,
    total: total,
  );
}
