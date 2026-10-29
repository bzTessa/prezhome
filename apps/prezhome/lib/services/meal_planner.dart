import 'dart:math';

import '../models/recipe.dart';

/// Generador del plan semanal (v1, basado en reglas + aprendizaje ligero).
///
/// Reglas:
///  - Solo asigna recetas del tipo de comida correspondiente.
///  - Da variedad: evita repetir la misma receta en días seguidos.
///  - Pondera: favoritas y recetas "aceptadas" antes tienen más peso; las
///    "rechazadas" menos. Ese peso viene de scoreByRecipe (historial).
///  - No repite demasiado: cada uso en la semana resta peso (en lote se
///    permite repetir una receta dos veces, que es cocinar una tanda).
///  - Medianamente equilibrado: en comida y cena reparte legumbre, pescado,
///    huevo y carne según [weeklyTargets] y evita el mismo grupo seguido.
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

  /// Veces por semana que se busca cada grupo en comidas y cenas (pauta
  /// habitual: legumbre y pescado 3, huevo 2, carne como mucho 3).
  static const weeklyTargets = {
    ProteinGroup.legumbre: 3,
    ProteinGroup.pescado: 3,
    ProteinGroup.huevo: 2,
    ProteinGroup.carne: 3,
  };

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
    // Cocina en lote: repetir una receta dos veces es lo esperado.
    bool batch = false,
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
    // Usos de cada receta en la semana y de cada grupo en comidas/cenas.
    final uses = <String, int>{};
    final groupCount = <ProteinGroup, int>{};
    ProteinGroup? lastMainGroup;

    for (var d = 0; d < days; d++) {
      // Planes de varias semanas: la pauta y los usos cuentan por semana.
      if (d > 0 && d % 7 == 0) {
        uses.clear();
        groupCount.clear();
      }
      final date = DateTime(startDate.year, startDate.month, startDate.day + d);
      final dayMap = <String, String>{};

      for (final type in mealTypes) {
        final all = byType[type] ?? [];
        if (all.isEmpty) continue;
        // Lo mismo dos veces el mismo día, solo si no hay otra cosa.
        final fresh = all.where((r) => !dayMap.containsValue(r.id)).toList();
        final options = fresh.isEmpty ? all : fresh;

        final isMain = type == 'lunch' || type == 'dinner';
        final picked = _pickWeighted(
          options: options,
          recentIds: recent[type]!,
          scoreByRecipe: scoreByRecipe,
          frozenRecipeIds: frozenRecipeIds,
          frozenBoost: frozenBoost,
          extra: (r) {
            var w = _repeatFactor(uses[r.id] ?? 0, batch);
            if (isMain) {
              final g = proteinGroupOf(r);
              final target = weeklyTargets[g];
              if (target != null) {
                w *= (groupCount[g] ?? 0) >= target ? 0.25 : 1.4;
              }
              if (g != ProteinGroup.otro && g == lastMainGroup) w *= 0.5;
            }
            return w;
          },
          recentPenalty: batch ? 0.7 : 0.15,
        );
        if (picked != null) {
          dayMap[type] = picked.id;
          uses[picked.id] = (uses[picked.id] ?? 0) + 1;
          if (isMain) {
            final g = proteinGroupOf(picked);
            groupCount[g] = (groupCount[g] ?? 0) + 1;
            lastMainGroup = g;
          }
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
    double Function(Recipe)? extra,
    double recentPenalty = 0.15,
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
      if (recentIds.contains(r.id)) w *= recentPenalty; // repetir seguido
      if (extra != null) w *= extra(r);
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

  /// Peso por usos previos en la semana: cada repetición pesa menos. En lote
  /// la segunda vez no penaliza (es la misma tanda).
  static double _repeatFactor(int uses, bool batch) {
    final extraUses = batch ? uses - 1 : uses;
    return extraUses <= 0 ? 1 : pow(0.25, extraUses).toDouble();
  }
}

/// Grupo principal de una receta, para equilibrar la semana.
enum ProteinGroup { legumbre, pescado, huevo, carne, otro }

const _groupWords = {
  ProteinGroup.legumbre: [
    'lenteja',
    'garbanzo',
    'alubia',
    'judión',
    'fabada',
    'frijol',
    'hummus',
    'soja',
    'guisante',
    'habas',
  ],
  ProteinGroup.pescado: [
    'pescado',
    'merluza',
    'salmón',
    'salmon',
    'atún',
    'atun',
    'bacalao',
    'sardina',
    'gamba',
    'langostino',
    'calamar',
    'sepia',
    'pulpo',
    'dorada',
    'lubina',
    'mejillón',
    'marisco',
    'boquerón',
    'caballa',
    'rape',
  ],
  ProteinGroup.huevo: ['huevo', 'tortilla', 'revuelto'],
  ProteinGroup.carne: [
    'pollo',
    'pavo',
    'ternera',
    'cerdo',
    'carne',
    'lomo',
    'jamón',
    'chorizo',
    'hamburguesa',
    'albóndiga',
    'cordero',
    'conejo',
    'solomillo',
    'costilla',
    'salchicha',
    'bacon',
    'beicon',
    'pechuga',
    'muslo',
  ],
};

/// Clasifica por el nombre y las partes del plato. El orden importa: unos
/// garbanzos con jamón son legumbre.
ProteinGroup proteinGroupOf(Recipe r) {
  final text = [
    r.title,
    for (final c in r.components) c.name,
  ].join(' ').toLowerCase();
  for (final e in _groupWords.entries) {
    if (e.value.any(text.contains)) return e.key;
  }
  return ProteinGroup.otro;
}
