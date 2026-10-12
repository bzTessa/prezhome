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

  /// Sesgo (boost de peso) hacia recetas con platos congelados disponibles,
  /// según la energía de la semana. Con energía baja (cocinar poco) el boost es
  /// MUY alto para que el plan tire con fuerza del congelador y así cocinar
  /// menos; con energía normal es moderado; con energía alta no hay sesgo
  /// (preferimos cocinar fresco). Son constantes nombradas para que el umbral
  /// sea explícito y fácil de ajustar/testear.
  static const double frozenBoostEnergiaBaja = 12.0; // energyLevel = 0
  static const double frozenBoostEnergiaNormal = 2.0; // energyLevel = 1
  static const double frozenBoostEnergiaAlta = 0.0; // energyLevel = 2

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
    // Recetas de las que hay platos congelados disponibles. Con energía baja,
    // se priorizan mucho (cocinar menos, tirar del congelador).
    Set<String> frozenRecipeIds = const {},
    // 0 = cocinar poco (usa congelado), 1 = normal, 2 = cocinar mucho (fresco).
    int energyLevel = 1,
  }) {
    final plan = <DateTime, Map<String, String>>{};

    // Sesgo hacia recetas con congelado según la energía. Con energía baja el
    // boost es claramente mayor (ver constantes) para que "cocinar poco" tire
    // de verdad del congelador en vez de proponer cocinar de cero.
    final frozenBoost = energyLevel <= 0
        ? frozenBoostEnergiaBaja
        : energyLevel == 1
        ? frozenBoostEnergiaNormal
        : frozenBoostEnergiaAlta;

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
          frozenRecipeIds: frozenRecipeIds,
          frozenBoost: frozenBoost,
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
    Set<String> frozenRecipeIds = const {},
    double frozenBoost = 0,
  }) {
    if (options.isEmpty) return null;

    // Calcular peso de cada opción.
    final weights = <double>[];
    for (final r in options) {
      var w = 1.0;
      if (r.isFavorite) w += 1.5; // favoritas más probables
      w += (scoreByRecipe[r.id] ?? 0) * 0.5; // historial (aceptado/rechazado)
      if (frozenRecipeIds.contains(r.id)) {
        w += frozenBoost; // hay congelado: priorizar si la energía es baja
      }
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
