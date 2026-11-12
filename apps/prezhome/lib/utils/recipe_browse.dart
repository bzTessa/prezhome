import '../models/recipe.dart';
import 'pantry_ideas.dart';
import 'shopping_categories.dart' show normalizeCategoryText;

/// Categorías para explorar el recetario, en el orden en que se enseñan.
/// Una receta puede estar en varias (una cena rápida y ligera sale en las tres).
const recipeBrowseCategories = [
  'favorites',
  'quick',
  'light',
  'breakfast',
  'lunch',
  'dinner',
  'dessert',
  'snack',
  'drink',
  'freezer',
];

/// "Rápidas": lista en este tiempo total o menos.
const quickRecipeMinutes = 20;

/// "Ligeras": esta energía por ración o menos.
const lightRecipeKcal = 400;

bool recipeInCategory(Recipe r, String category) => switch (category) {
  'favorites' => r.isFavorite,
  'quick' => switch (r.totalTimeMinutes) {
    final int m => m > 0 && m <= quickRecipeMinutes,
    null => false,
  },
  'light' => r.calories != null && r.calories! <= lightRecipeKcal,
  'freezer' => r.freezesWell,
  _ => r.mealTypes.contains(category),
};

/// Cuántas recetas hay en cada categoría (solo las que tienen alguna).
Map<String, int> recipeCategoryCounts(List<Recipe> recipes) => {
  for (final c in recipeBrowseCategories)
    if (recipes.where((r) => recipeInCategory(r, c)).length case final n
        when n > 0)
      c: n,
};

List<String> _words(String query) => normalizeCategoryText(
  query,
).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// Cada palabra buscada debe salir en el nombre, la descripción o algún
/// ingrediente, sin importar acentos ni mayúsculas ("pollo arroz" encuentra
/// "Bowl de pollo salteado" si lleva arroz).
bool recipeMatchesQuery(Recipe r, String query) {
  final words = _words(query);
  if (words.isEmpty) return true;
  final text = normalizeCategoryText(
    [r.title, r.description ?? '', ...r.ingredientNames].join(' '),
  );
  return words.every(text.contains);
}

enum RecipeSort { recent, az, fastest, lightest }

/// Filtra por texto y categoría y ordena. Con texto, las recetas cuyo nombre
/// coincide van antes que las que solo coinciden por ingrediente.
/// [RecipeSort.recent] respeta el orden de entrada (más nuevas primero).
List<Recipe> browseRecipes(
  List<Recipe> recipes, {
  String query = '',
  String? category,
  RecipeSort sort = RecipeSort.recent,
}) {
  final found = [
    for (final r in recipes)
      if ((category == null || recipeInCategory(r, category)) &&
          recipeMatchesQuery(r, query))
        r,
  ];
  final int? Function(Recipe)? key = switch (sort) {
    RecipeSort.fastest => (r) => r.totalTimeMinutes,
    RecipeSort.lightest => (r) => r.calories,
    _ => null,
  };
  if (sort == RecipeSort.az) {
    found.sort(
      (a, b) => normalizeCategoryText(
        a.title,
      ).compareTo(normalizeCategoryText(b.title)),
    );
  } else if (key != null) {
    // Sin dato al final; los empates conservan el orden de entrada.
    final pos = {for (var i = 0; i < found.length; i++) found[i]: i};
    found.sort((a, b) {
      final ka = key(a), kb = key(b);
      if (ka != kb) {
        if (ka == null) return 1;
        if (kb == null) return -1;
        return ka.compareTo(kb);
      }
      return pos[a]!.compareTo(pos[b]!);
    });
  }
  final words = _words(query);
  if (words.isEmpty) return found;
  bool inTitle(Recipe r) {
    final t = normalizeCategoryText(r.title);
    return words.every(t.contains);
  }

  return [...found.where(inTitle), ...found.where((r) => !inTitle(r))];
}

/// Cuántos ingredientes de [r] faltan en casa según la despensa [pantry]
/// (los básicos como sal o aceite se dan por supuestos). Null si no se puede
/// saber: receta sin ingredientes cargados, despensa vacía o ningún
/// ingrediente en casa (así una receta vacía no parece "lista").
int? missingAtHome(Recipe r, List<String> pantry) {
  if (pantry.isEmpty || r.ingredientNames.isEmpty) return null;
  final split = splitByPantry(r.ingredientNames, pantry);
  if (split.have.isEmpty) return null;
  return split.missing.length;
}

/// Recetas que se pueden cocinar ya: no falta nada y hay al menos dos
/// ingredientes en casa (una receta de "sal y agua" no cuenta).
List<Recipe> readyToCook(List<Recipe> recipes, List<String> pantry) => [
  for (final r in recipes)
    if (missingAtHome(r, pantry) == 0 &&
        splitByPantry(r.ingredientNames, pantry).have.length >= 2)
      r,
];
