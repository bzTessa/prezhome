/// Cerebro de la LOGÍSTICA del meal prep: a partir del plan semanal de comidas
/// decide qué día(s) cocinar en lote, cuántas raciones van a la NEVERA (consumo
/// cercano) y cuántas al CONGELADOR (consumo lejano, solo si la receta es
/// congelable), y cuándo conviene SACAR cada cosa del congelador.
///
/// Toda la lógica de este archivo es PURA: no importa Flutter ni Supabase, solo
/// dart:core. Recibe los datos que necesita (entradas del plan + un mapa de
/// recetas) y devuelve un modelo con el plan de cocción y un resumen cozy en
/// español. Así es determinista y fácil de testear con fechas fijas.
///
/// Filosofía (de Tessa): flexibilidad por encima de perfección. No buscamos el
/// reparto óptimo de cocciones, sino uno RAZONABLE y entendible: concentrar la
/// cocción en 1-2 días y tirar del congelador cuando toque cocinar poco.
library;

/// Umbral de días para decidir NEVERA vs CONGELADOR: una ración se guarda en la
/// nevera si se va a consumir dentro de los próximos [kDiasNevera] días desde el
/// día de cocción (incluido). El resto va al congelador (si es congelable).
const int kDiasNevera = 3;

/// Días antes del consumo en que se sugiere SACAR del congelador para que
/// descongele a tiempo. Se resta a la fecha de consumo.
const int kDiasSacarAntes = 1;

/// Ventana de congelación por defecto (en días) cuando una receta no indica
/// `freezerDays`. Debe coincidir con `InventoryItem.defaultFreezerDays` para
/// mantener una sola fuente de verdad conceptual (90 días ≈ 3 meses).
const int kDiasCongeladorPorDefecto = 90;

/// Número máximo de días de cocción propuestos según la energía de la semana.
/// Con energía baja (cocinar poco) agrupamos en un único día; con energía alta
/// (cocinar mucho) permitimos repartir en más días para comer más fresco.
const int kDiasCoccionEnergiaBaja = 1; // energyLevel = 0
const int kDiasCoccionEnergiaNormal = 2; // energyLevel = 1
const int kDiasCoccionEnergiaAlta = 3; // energyLevel = 2

/// Nombres de los días de la semana en español (1=Lunes .. 7=Domingo).
const List<String> _diasSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// Datos mínimos de una receta que necesita la logística del meal prep. Es un
/// espejo reducido de `Recipe` para que el cerebro no dependa del modelo de la
/// app (y por tanto de Flutter). Lo construye quien llama a partir de `Recipe`.
class PrepRecipe {
  final String id;
  final String title;
  final bool freezable;

  /// Días recomendados de congelación (si se conoce). Si es null se usa
  /// [kDiasCongeladorPorDefecto].
  final int? freezerDays;

  /// Tiempos (opcionales) para ordenar qué cocinar primero dentro de un día:
  /// primero lo que más tarda (prep + cook), para aprovechar el horno/olla.
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;

  const PrepRecipe({
    required this.id,
    required this.title,
    this.freezable = false,
    this.freezerDays,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
  });

  /// Tiempo total estimado (prep + cook) en minutos; 0 si no se conoce ninguno.
  int get totalTimeMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);
}

/// Una comida del plan que hay que cocinar: receta, fecha de consumo y raciones.
class PrepMeal {
  final String recipeId;

  /// Día en que se consume esa comida (solo cuenta año/mes/día).
  final DateTime date;

  /// Tipo de comida (breakfast/lunch/dinner/snack/dessert); informativo.
  final String mealType;

  /// Raciones a cocinar para esa comida (personas que comen en casa).
  final int servings;

  const PrepMeal({
    required this.recipeId,
    required this.date,
    required this.mealType,
    this.servings = 1,
  });

  DateTime get _day => DateTime(date.year, date.month, date.day);
}

/// Qué hacer con las raciones cocinadas de una receta en un día de cocción.
class PrepBatch {
  final String recipeId;
  final String title;

  /// Raciones totales a cocinar de esta receta ese día.
  final int totalServings;

  /// Raciones que van a la NEVERA (consumo cercano).
  final int fridgeServings;

  /// Raciones que van al CONGELADOR (consumo lejano, solo si es congelable).
  final int freezerServings;

  /// Fecha sugerida para SACAR del congelador la tanda congelada (la más
  /// temprana entre las raciones congeladas). null si no hay congelador.
  final DateTime? takeOutDate;

  const PrepBatch({
    required this.recipeId,
    required this.title,
    required this.totalServings,
    required this.fridgeServings,
    required this.freezerServings,
    this.takeOutDate,
  });
}

/// Un día en el que se propone cocinar en lote, con sus tandas.
class CookingDay {
  final DateTime date;
  final List<PrepBatch> batches;

  const CookingDay({required this.date, required this.batches});

  /// Raciones totales a cocinar ese día (suma de todas las tandas).
  int get totalServings => batches.fold(0, (sum, b) => sum + b.totalServings);
}

/// Plan de cocción completo de la semana: la lista de días de cocción.
class MealPrepPlan {
  final List<CookingDay> cookingDays;

  const MealPrepPlan({required this.cookingDays});

  bool get isEmpty => cookingDays.isEmpty;
  bool get isNotEmpty => cookingDays.isNotEmpty;
}

/// Genera el plan de cocción del meal prep.
class MealPrepPlanner {
  const MealPrepPlanner();

  /// Construye el plan de cocción a partir de las [meals] del plan de la semana
  /// (una por comida con receta y raciones), un mapa [recipesById] con los
  /// datos de cada receta, la fecha de inicio de semana [weekStart] y el nivel
  /// de energía [energyLevel] (0=cocinar poco, 1=normal, 2=cocinar mucho).
  ///
  /// Heurística de agrupación (simple y flexible, sin buscar optimalidad):
  ///  - Elegimos como máximo N días de cocción según la energía (ver
  ///    [kDiasCoccionEnergiaBaja]/Normal/Alta).
  ///  - Repartimos la semana en bloques consecutivos y cada bloque se cocina
  ///    el PRIMER día del bloque que tenga comidas en casa. Así, con energía
  ///    baja todo se cocina un día (y lo lejano tira del congelador) y con
  ///    energía alta se cocina en más días (más fresco, menos congelador).
  MealPrepPlan buildPlan({
    required List<PrepMeal> meals,
    required Map<String, PrepRecipe> recipesById,
    required DateTime weekStart,
    int energyLevel = 1,
  }) {
    // Solo nos interesan comidas con receta conocida y al menos una ración.
    final relevant = meals
        .where((m) => recipesById.containsKey(m.recipeId) && m.servings > 0)
        .toList()
      ..sort((a, b) => a._day.compareTo(b._day));
    if (relevant.isEmpty) {
      return const MealPrepPlan(cookingDays: []);
    }

    final maxCookingDays = _maxCookingDays(energyLevel);

    // Días (normalizados) que tienen al menos una comida en casa, ordenados.
    final mealDays = <DateTime>[];
    for (final m in relevant) {
      if (!mealDays.contains(m._day)) mealDays.add(m._day);
    }
    mealDays.sort();

    // Repartimos los días con comida en como mucho [maxCookingDays] bloques
    // consecutivos y cada bloque se cuece el primer día del bloque.
    final cookDates = _chooseCookDates(mealDays, maxCookingDays);

    // Para cada día de cocción, asignamos las comidas del bloque que arranca en
    // ese día de cocción y acaba antes del siguiente día de cocción.
    final cookingDays = <CookingDay>[];
    for (var i = 0; i < cookDates.length; i++) {
      final cookDate = cookDates[i];
      final nextCook = i + 1 < cookDates.length ? cookDates[i + 1] : null;

      final mealsOfBlock = relevant.where((m) {
        final day = m._day;
        final afterStart = !day.isBefore(cookDate);
        final beforeNext = nextCook == null || day.isBefore(nextCook);
        return afterStart && beforeNext;
      }).toList();

      final batches = _batchesForDay(
        cookDate: cookDate,
        meals: mealsOfBlock,
        recipesById: recipesById,
      );
      if (batches.isNotEmpty) {
        cookingDays.add(CookingDay(date: cookDate, batches: batches));
      }
    }

    return MealPrepPlan(cookingDays: cookingDays);
  }

  /// Días de cocción máximos permitidos según la energía de la semana.
  int _maxCookingDays(int energyLevel) {
    if (energyLevel <= 0) return kDiasCoccionEnergiaBaja;
    if (energyLevel == 1) return kDiasCoccionEnergiaNormal;
    return kDiasCoccionEnergiaAlta;
  }

  /// Elige las fechas de cocción repartiendo [mealDays] (días con comida en
  /// casa) en como mucho [maxDays] bloques consecutivos. El día de cocción de
  /// cada bloque es el primer día del bloque.
  List<DateTime> _chooseCookDates(List<DateTime> mealDays, int maxDays) {
    if (mealDays.isEmpty) return const [];
    final blocks = maxDays < 1 ? 1 : maxDays;
    if (blocks >= mealDays.length) {
      // Caben todos: cada día con comida es su propio día de cocción (fresco).
      return List<DateTime>.from(mealDays);
    }
    // Repartimos los días en [blocks] trozos lo más equilibrados posible y
    // cogemos el primer día de cada trozo como día de cocción.
    final cookDates = <DateTime>[];
    final n = mealDays.length;
    for (var b = 0; b < blocks; b++) {
      final startIdx = (b * n) ~/ blocks;
      cookDates.add(mealDays[startIdx]);
    }
    return cookDates;
  }

  /// Construye las tandas (una por receta) para un día de cocción, repartiendo
  /// cada ración entre nevera y congelador según cuándo se consume.
  List<PrepBatch> _batchesForDay({
    required DateTime cookDate,
    required List<PrepMeal> meals,
    required Map<String, PrepRecipe> recipesById,
  }) {
    // Agrupamos por receta para cocinar en lote.
    final byRecipe = <String, List<PrepMeal>>{};
    for (final m in meals) {
      byRecipe.putIfAbsent(m.recipeId, () => []).add(m);
    }

    final batches = <PrepBatch>[];
    byRecipe.forEach((recipeId, recipeMeals) {
      final recipe = recipesById[recipeId]!;
      var total = 0;
      var fridge = 0;
      var freezer = 0;
      DateTime? earliestFreezerConsumption;

      for (final meal in recipeMeals) {
        final daysAhead = meal._day.difference(cookDate).inDays;
        final goesToFridge = daysAhead <= kDiasNevera;
        if (goesToFridge || !recipe.freezable) {
          // Consumo cercano, o receta no congelable: siempre a la nevera.
          fridge += meal.servings;
        } else {
          freezer += meal.servings;
          if (earliestFreezerConsumption == null ||
              meal._day.isBefore(earliestFreezerConsumption)) {
            earliestFreezerConsumption = meal._day;
          }
        }
        total += meal.servings;
      }

      final takeOut = earliestFreezerConsumption == null
          ? null
          : _takeOutDate(
              consumption: earliestFreezerConsumption,
              cookDate: cookDate,
            );

      batches.add(
        PrepBatch(
          recipeId: recipeId,
          title: recipe.title,
          totalServings: total,
          fridgeServings: fridge,
          freezerServings: freezer,
          takeOutDate: takeOut,
        ),
      );
    });

    // Primero lo que más tarda en cocinarse (horno/olla), para aprovechar.
    batches.sort((a, b) {
      final ra = recipesById[a.recipeId]!;
      final rb = recipesById[b.recipeId]!;
      return rb.totalTimeMinutes.compareTo(ra.totalTimeMinutes);
    });

    return batches;
  }

  /// Fecha sugerida para SACAR del congelador: el día de consumo menos
  /// [kDiasSacarAntes], pero nunca antes del día de cocción (no tiene sentido
  /// sacar algo antes de haberlo congelado).
  DateTime _takeOutDate({
    required DateTime consumption,
    required DateTime cookDate,
  }) {
    final suggested = consumption.subtract(
      const Duration(days: kDiasSacarAntes),
    );
    return suggested.isBefore(cookDate) ? cookDate : suggested;
  }
}

/// Nombre del día de la semana en español (1=Lunes .. 7=Domingo).
String _diaSemana(DateTime date) => _diasSemana[date.weekday - 1];

/// Genera el resumen cozy en español de un día de cocción, estilo:
/// "Domingo cocinas: lentejas (x6) y pollo (x4). 3 raciones a la nevera, 3 al
/// congelador. Saca el pollo el miércoles."
///
/// Función PURA (separada de la UI) para poder testearla con datos fijos.
String resumenDiaCoccion(CookingDay day) {
  final dia = _capitalizar(_diaSemana(day.date));

  // Lista de recetas con sus raciones: "lentejas (x6) y pollo (x4)".
  final recetas = day.batches
      .map((b) => '${b.title} (x${b.totalServings})')
      .toList();
  final listaRecetas = _unirConY(recetas);

  final buffer = StringBuffer('$dia cocinas: $listaRecetas.');

  final totalFridge = day.batches.fold<int>(0, (s, b) => s + b.fridgeServings);
  final totalFreezer = day.batches.fold<int>(
    0,
    (s, b) => s + b.freezerServings,
  );

  final partes = <String>[];
  if (totalFridge > 0) {
    partes.add('$totalFridge ${_raciones(totalFridge)} a la nevera');
  }
  if (totalFreezer > 0) {
    partes.add('$totalFreezer al congelador');
  }
  if (partes.isNotEmpty) {
    // Estilo del ejemplo: "3 raciones a la nevera, 3 al congelador." (coma).
    buffer.write(' ${_capitalizar(partes.join(', '))}.');
  }

  // Avisos de "saca del congelador" por receta con tanda congelada.
  final sacar = <String>[];
  for (final b in day.batches) {
    if (b.freezerServings > 0 && b.takeOutDate != null) {
      sacar.add('${b.title} el ${_diaSemana(b.takeOutDate!)}');
    }
  }
  for (final s in sacar) {
    buffer.write(' Saca $s.');
  }

  return buffer.toString();
}

/// Resumen completo del plan de cocción (una frase por día de cocción).
String resumenPlanCoccion(MealPrepPlan plan) {
  if (plan.isEmpty) {
    return 'Esta semana no hay nada que cocinar en lote todavía.';
  }
  return plan.cookingDays.map(resumenDiaCoccion).join('\n');
}

/// Une una lista con comas y una "y" final: ["a","b","c"] -> "a, b y c".
String _unirConY(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  final todosMenosUltimo = items.sublist(0, items.length - 1);
  return '${todosMenosUltimo.join(', ')} y ${items.last}';
}

/// "ración" en singular cuando toca, "raciones" en el resto.
String _raciones(int n) => n == 1 ? 'ración' : 'raciones';

/// Pone la primera letra en mayúscula (respetando el resto).
String _capitalizar(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
