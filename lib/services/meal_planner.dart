import 'dart:math';

import '../models/recipe.dart';

/// Generador del plan semanal (v1, basado en reglas + aprendizaje ligero).
///
/// Reglas:
///  - Solo asigna recetas del tipo de comida correspondiente.
///  - Da variedad: evita repetir la misma receta en días seguidos.
///  - Pondera: favoritas y recetas "aceptadas" antes tienen más peso; las
///    "rechazadas" menos. Ese peso viene de scoreByRecipe (historial).
class MealPlanner {
  final Random _random;
  MealPlanner({int? seed}) : _random = Random(seed);

  /// Genera un plan para [days] días a partir de [startDate].
  ///
  /// [mealTypes]: comidas activas a planificar (ej. ['lunch','dinner']).
  /// [recipes]: recetas disponibles del hogar.
  /// [scoreByRecipe]: peso extra por receta (>0 sube prob., <0 baja). Opcional.
  ///
  /// Devuelve un mapa: fecha -> (tipo -> recipeId). Si no hay receta para un
  /// hueco, no lo incluye.
  Map<DateTime, Map<String, String>> generate({
    required DateTime startDate,
    required int days,
    required List<String> mealTypes,
    required List<Recipe> recipes,
    Map<String, int> scoreByRecipe = const {},
  }) {
    final plan = <DateTime, Map<String, String>>{};

    // Agrupar recetas por tipo de comida.
    final byType = <String, List<Recipe>>{};
    for (final type in mealTypes) {
      byType[type] = recipes.where((r) => r.mealTypes.contains(type)).toList();
    }

    // Para dar variedad: recordar las últimas usadas por tipo.
    final recent = <String, List<String>>{for (final t in mealTypes) t: []};

    for (var d = 0; d < days; d++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day + d);
      final dayMap = <String, String>{};

      for (final type in mealTypes) {
        final options = byType[type] ?? [];
        if (options.isEmpty) continue;

        final picked = _pickWeighted(
          options: options,
          recentIds: recent[type]!,
          scoreByRecipe: scoreByRecipe,
        );
        if (picked != null) {
          dayMap[type] = picked.id;
          // Mantener una ventana de "recientes" para no repetir seguido.
          final r = recent[type]!;
          r.add(picked.id);
          if (r.length > 2) r.removeAt(0); // no repetir en 2-3 días
        }
      }

      if (dayMap.isNotEmpty) plan[date] = dayMap;
    }

    return plan;
  }

  /// Elige una receta ponderada: penaliza las recientes, favorece favoritas y
  /// las de mejor score. Nunca devuelve null si hay opciones.
  Recipe? _pickWeighted({
    required List<Recipe> options,
    required List<String> recentIds,
    required Map<String, int> scoreByRecipe,
  }) {
    if (options.isEmpty) return null;

    // Calcular peso de cada opción.
    final weights = <double>[];
    for (final r in options) {
      var w = 1.0;
      if (r.isFavorite) w += 1.5; // favoritas más probables
      w += (scoreByRecipe[r.id] ?? 0) * 0.5; // historial (aceptado/rechazado)
      if (recentIds.contains(r.id)) w *= 0.15; // penaliza repetir seguido
      if (w < 0.05) w = 0.05; // nunca cero del todo
      weights.add(w);
    }

    final total = weights.fold<double>(0, (a, b) => a + b);
    var pick = _random.nextDouble() * total;
    for (var i = 0; i < options.length; i++) {
      pick -= weights[i];
      if (pick <= 0) return options[i];
    }
    return options.last;
  }
}
