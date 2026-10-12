/// Orquestador del BATCH COOKING: a partir de un conjunto de recetas que se van
/// a cocinar a la vez, construye una LÍNEA DE TIEMPO unificada de pasos. La idea
/// clave es aprovechar los aparatos: si dos platos usan el horno, se encienden
/// de una sola vez (un único bloque de cocción que cubre ambas recetas) en vez
/// de encenderlo dos veces por separado. Además marca los pasos de preparación
/// que pueden hacerse EN PARALELO mientras un aparato está ocupado.
///
/// Toda la lógica de este archivo es PURA: no importa Flutter ni Supabase, solo
/// dart:core. Recibe un espejo reducido de las recetas y devuelve un modelo con
/// la línea de tiempo y un resumen cercano en español. Así es determinista y
/// fácil de testear con datos fijos.
///
/// Filosofía (igual que meal_prep_planner): flexibilidad por encima de
/// perfección. No buscamos el calendario ÓPTIMO de un scheduler industrial,
/// sino uno RAZONABLE y entendible: agrupar las cocciones que comparten aparato
/// y dejar que las preparaciones manuales solapen con lo que está en el fuego.
library;

/// Valor de `appliance` que indica que un paso NO usa ningún aparato (trabajo
/// manual de preparación: cortar, mezclar, emplatar...). Nunca se agrupa por
/// aparato y es candidato a correr en paralelo.
const String kApplianceNone = 'none';

/// Minutos por defecto que asignamos a un paso derivado de una receta que no
/// indica ni tiempo de preparación ni de cocción. Mantiene el total realista
/// sin inventar datos concretos (un paso "existe" aunque no sepamos cuánto
/// dura exactamente). Documentado para que los tests sean predecibles.
const int kDuracionPasoPorDefecto = 0;

/// Etiquetas en español de los aparatos conocidos, para el resumen cercano.
/// Si llega un aparato desconocido se usa su propio identificador tal cual.
const Map<String, String> _etiquetasAparato = {
  'oven': 'el horno',
  'stovetop': 'los fogones',
  'pot': 'la olla',
  'airfryer': 'la freidora de aire',
  'microwave': 'el microondas',
};

/// Datos mínimos de una receta que necesita el orquestador. Es un espejo
/// reducido de `Recipe` para que el orquestador no dependa del modelo de la app
/// (y por tanto de Flutter). Lo construye quien llama a partir de `Recipe`,
/// igual que `PrepRecipe` en el planner.
class OrchestratorRecipe {
  final String id;
  final String title;

  /// Aparato principal de la receta ('none'|'oven'|'stovetop'|'pot'|
  /// 'airfryer'|'microwave'). 'none' = solo trabajo manual.
  final String appliance;

  /// Tiempos (opcionales) en minutos. Reparten la estimación entre los pasos
  /// de preparación y marcan la duración de la cocción.
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;

  /// Texto multilínea con los pasos de la receta (opcional). Si viene, se
  /// derivan los pasos de ahí; si no, se genera un único paso genérico.
  final String? instructions;

  const OrchestratorRecipe({
    required this.id,
    required this.title,
    this.appliance = kApplianceNone,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.instructions,
  });

  /// Tiempo total estimado (prep + cook) en minutos; 0 si no se conoce ninguno.
  int get totalTimeMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  /// true si la receta usa un aparato de cocción (distinto de 'none').
  bool get usaAparato => appliance != kApplianceNone && appliance.isNotEmpty;
}

/// Un paso dentro de la línea de tiempo. Puede corresponder a una sola receta
/// (preparación) o a varias (un bloque de cocción que comparte aparato).
class TimelineStep {
  /// Texto del paso, p. ej. "Precalienta el horno" o "Corta la cebolla".
  final String title;

  /// Títulos de las recetas que cubre este paso. Para un bloque de cocción
  /// agrupado habrá más de uno; para un paso normal, uno.
  final List<String> recipeTitles;

  /// Aparato que usa el paso ('none' para trabajo manual).
  final String appliance;

  /// Duración estimada en minutos (0 si no se conoce; ver
  /// [kDuracionPasoPorDefecto]).
  final int durationMinutes;

  /// true si este paso puede solaparse con el anterior (p. ej. una preparación
  /// manual mientras algo está en el horno). Si es true, su duración NO se
  /// suma en serie al total.
  final bool canRunInParallel;

  /// true si es un paso de preparación/manual (appliance 'none'); false si es
  /// un paso de cocción con aparato.
  final bool isPrep;

  const TimelineStep({
    required this.title,
    required this.recipeTitles,
    required this.appliance,
    required this.durationMinutes,
    this.canRunInParallel = false,
    this.isPrep = false,
  });

  /// true si este paso agrupa varias recetas (bloque de cocción compartido).
  bool get agrupaVariasRecetas => recipeTitles.length > 1;

  @override
  bool operator ==(Object other) =>
      other is TimelineStep &&
      other.title == title &&
      _listEquals(other.recipeTitles, recipeTitles) &&
      other.appliance == appliance &&
      other.durationMinutes == durationMinutes &&
      other.canRunInParallel == canRunInParallel &&
      other.isPrep == isPrep;

  @override
  int get hashCode => Object.hash(
    title,
    Object.hashAll(recipeTitles),
    appliance,
    durationMinutes,
    canRunInParallel,
    isPrep,
  );

  @override
  String toString() =>
      'TimelineStep($title, recetas=$recipeTitles, aparato=$appliance, '
      'min=$durationMinutes, paralelo=$canRunInParallel, prep=$isPrep)';
}

/// Línea de tiempo completa del batch cooking: la lista ordenada de pasos.
class TimelinePlan {
  final List<TimelineStep> steps;

  const TimelinePlan({required this.steps});

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;

  /// Minutos totales estimados de forma REALISTA, acotando el solape para no
  /// prometer tiempos irreales.
  ///
  /// Dos "carriles" discurren a la vez: los pasos que ocupan un aparato
  /// (cocción, en serie porque hay que esperar a que cada uno termine) y las
  /// preparaciones manuales que pueden adelantarse mientras algo cuece. Esas
  /// preparaciones SOLO caben dentro del tiempo que los aparatos están
  /// ocupados; lo que no quepa en esa ventana se hace después, en serie.
  ///
  /// Fórmula (simple y explicable):
  ///   - `tiempoAparatos` = suma en serie de los pasos de cocción (los bloques
  ///     agrupados cuentan una sola vez su máximo, no la suma del grupo).
  ///   - `prepParalela`  = suma de las preparaciones marcadas solapables.
  ///   - `prepSerie`     = suma de las preparaciones que van en serie.
  ///   - total = prepSerie + max(tiempoAparatos, prepParalela)
  ///
  /// Así, cuando la cocción domina (caso típico: dos platos al horno) la prep
  /// se "esconde" dentro del tiempo de aparato y no suma; pero cuando la
  /// preparación manual es mucho mayor que la cocción, el total NO baja de la
  /// preparación real: el solape no puede inventar tiempo que no existe.
  int get totalEstimatedMinutes {
    var tiempoAparatos = 0;
    var prepParalela = 0;
    var prepSerie = 0;
    for (final step in steps) {
      if (step.isPrep) {
        if (step.canRunInParallel) {
          prepParalela += step.durationMinutes;
        } else {
          prepSerie += step.durationMinutes;
        }
      } else {
        // Paso de cocción: ocupa un aparato y se hace en serie.
        tiempoAparatos += step.durationMinutes;
      }
    }
    final solapado = tiempoAparatos > prepParalela
        ? tiempoAparatos
        : prepParalela;
    return prepSerie + solapado;
  }
}

/// Construye la línea de tiempo del batch cooking.
class MealPrepOrchestrator {
  const MealPrepOrchestrator();

  /// Construye la línea de tiempo a partir de las [recipes] que se van a
  /// cocinar juntas.
  ///
  /// Heurística (simple y explicable, sin buscar optimalidad):
  ///  - Ordenamos las recetas por tiempo total DESC (lo que más tarda primero),
  ///    igual que `_batchesForDay` del planner, para aprovechar el aparato.
  ///  - Las COCCIONES que comparten el mismo aparato (distinto de 'none') se
  ///    FUSIONAN en un solo bloque que cubre todas esas recetas, con duración =
  ///    el MÁXIMO de las cocciones del grupo (no la suma): el horno está
  ///    encendido una vez para todas. Aparatos distintos no se fusionan.
  ///  - Las PREPARACIONES (appliance 'none') que se pueden hacer mientras algún
  ///    aparato ya está ocupado se marcan `canRunInParallel = true` (solapan y
  ///    no suman al total). El resto queda en serie.
  TimelinePlan buildTimeline({required List<OrchestratorRecipe> recipes}) {
    if (recipes.isEmpty) {
      return const TimelinePlan(steps: []);
    }

    // Orden determinista: primero lo que más tarda (prep + cook) y, a igualdad,
    // por id para que el resultado no dependa del orden de entrada.
    final ordered = [...recipes]
      ..sort((a, b) {
        final cmp = b.totalTimeMinutes.compareTo(a.totalTimeMinutes);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

    // Derivamos los pasos de cada receta, separando preparación de cocción.
    final prepSteps = <TimelineStep>[];
    final cookStepsByRecipe = <_RecipeCookStep>[];
    for (final recipe in ordered) {
      final derived = _derivarPasos(recipe);
      prepSteps.addAll(derived.prep);
      if (derived.cook != null) {
        cookStepsByRecipe.add(derived.cook!);
      }
    }

    // Agrupamos las cocciones por aparato (distinto de 'none'). Mantenemos el
    // orden de primera aparición (que ya viene por tiempo DESC) para que el
    // resultado sea determinista.
    final grupos = <String, List<_RecipeCookStep>>{};
    final ordenAparatos = <String>[];
    for (final cs in cookStepsByRecipe) {
      if (!grupos.containsKey(cs.appliance)) {
        grupos[cs.appliance] = [];
        ordenAparatos.add(cs.appliance);
      }
      grupos[cs.appliance]!.add(cs);
    }

    final cookSteps = <TimelineStep>[];
    for (final appliance in ordenAparatos) {
      final grupo = grupos[appliance]!;
      if (grupo.length == 1) {
        final cs = grupo.first;
        cookSteps.add(
          TimelineStep(
            title: cs.title,
            recipeTitles: [cs.recipeTitle],
            appliance: appliance,
            durationMinutes: cs.durationMinutes,
            isPrep: false,
          ),
        );
      } else {
        // Bloque compartido: un solo encendido del aparato para varias recetas.
        // Duración = el MÁXIMO de las cocciones del grupo (no la suma): el
        // aparato está encendido en paralelo para todas.
        final titulos = grupo.map((c) => c.recipeTitle).toList();
        final maxDuracion = grupo
            .map((c) => c.durationMinutes)
            .fold(0, (a, b) => a > b ? a : b);
        cookSteps.add(
          TimelineStep(
            title: '${_etiquetaUsar(appliance)} para ${_unirConY(titulos)}',
            recipeTitles: titulos,
            appliance: appliance,
            durationMinutes: maxDuracion,
            isPrep: false,
          ),
        );
      }
    }

    // Montamos la línea de tiempo: primero las cocciones (ocupan los aparatos)
    // y las preparaciones solapan en paralelo mientras haya algún aparato
    // ocupado. Si no hay ninguna cocción, las preparaciones van en serie.
    final hayCoccion = cookSteps.isNotEmpty;
    final steps = <TimelineStep>[];
    steps.addAll(cookSteps);
    for (final p in prepSteps) {
      steps.add(
        TimelineStep(
          title: p.title,
          recipeTitles: p.recipeTitles,
          appliance: p.appliance,
          durationMinutes: p.durationMinutes,
          // Una preparación manual puede solaparse si hay algo cocinándose.
          canRunInParallel: hayCoccion,
          isPrep: true,
        ),
      );
    }

    return TimelinePlan(steps: steps);
  }

  /// Deriva los pasos de una receta: una lista de pasos de preparación (manual)
  /// y, si procede, un paso de cocción con aparato.
  ///
  /// Reglas (sin inventar datos):
  ///  - Si `instructions` tiene contenido, se divide por líneas (descartando
  ///    vacías y tolerando numeración "1. " / "- "). Esas líneas son los pasos
  ///    de preparación y reparten la estimación de `prepTimeMinutes`.
  ///  - Si `instructions` está vacío, un único paso genérico `Preparar título`
  ///    con la estimación de preparación.
  ///  - Si la receta usa aparato y tiene `cookTimeMinutes`, se añade un paso de
  ///    cocción con esa duración. Si usa aparato pero no tiene tiempo, la
  ///    cocción dura [kDuracionPasoPorDefecto].
  _DerivedSteps _derivarPasos(OrchestratorRecipe recipe) {
    final prepTotal = recipe.prepTimeMinutes ?? kDuracionPasoPorDefecto;
    final lineas = _lineasInstrucciones(recipe.instructions);

    final prepSteps = <TimelineStep>[];
    if (lineas.isNotEmpty) {
      // Repartimos la estimación de preparación a partes iguales entre las
      // líneas (determinista: el resto se asigna a los primeros pasos).
      final base = prepTotal ~/ lineas.length;
      final resto = prepTotal % lineas.length;
      for (var i = 0; i < lineas.length; i++) {
        final dur = base + (i < resto ? 1 : 0);
        prepSteps.add(
          TimelineStep(
            title: lineas[i],
            recipeTitles: [recipe.title],
            appliance: kApplianceNone,
            durationMinutes: dur,
            isPrep: true,
          ),
        );
      }
    } else {
      prepSteps.add(
        TimelineStep(
          title: 'Preparar ${recipe.title}',
          recipeTitles: [recipe.title],
          appliance: kApplianceNone,
          durationMinutes: prepTotal,
          isPrep: true,
        ),
      );
    }

    _RecipeCookStep? cook;
    if (recipe.usaAparato) {
      final cookDur = recipe.cookTimeMinutes ?? kDuracionPasoPorDefecto;
      cook = _RecipeCookStep(
        recipeTitle: recipe.title,
        appliance: recipe.appliance,
        durationMinutes: cookDur,
        title: '${_etiquetaUsar(recipe.appliance)} para ${recipe.title}',
      );
    }

    return _DerivedSteps(prep: prepSteps, cook: cook);
  }

  /// Divide el texto de instrucciones en líneas limpias: descarta vacías y
  /// quita la numeración inicial ("1. ", "2) ", "- ", "* "). Si es null o
  /// vacío devuelve una lista vacía.
  List<String> _lineasInstrucciones(String? instructions) {
    if (instructions == null) return const [];
    final lineas = instructions
        .split('\n')
        .map((l) => _limpiarLinea(l))
        .where((l) => l.isNotEmpty)
        .toList();
    return lineas;
  }

  /// Quita espacios y la numeración/viñeta inicial de una línea.
  String _limpiarLinea(String linea) {
    var l = linea.trim();
    // Numeración tipo "1. ", "2) ", "10 - ".
    l = l.replaceFirst(RegExp(r'^\d+\s*[.)\-]\s*'), '');
    // Viñetas tipo "- ", "* ", "• ".
    l = l.replaceFirst(RegExp(r'^[\-*•]\s*'), '');
    return l.trim();
  }
}

/// Representación interna de una cocción de una receta antes de agruparla.
class _RecipeCookStep {
  final String recipeTitle;
  final String appliance;
  final int durationMinutes;
  final String title;

  const _RecipeCookStep({
    required this.recipeTitle,
    required this.appliance,
    required this.durationMinutes,
    required this.title,
  });
}

/// Resultado de derivar los pasos de una receta.
class _DerivedSteps {
  final List<TimelineStep> prep;
  final _RecipeCookStep? cook;

  const _DerivedSteps({required this.prep, this.cook});
}

/// Texto imperativo para usar un aparato en el título de un paso, p. ej.
/// "Enciende el horno". Para aparatos desconocidos cae a `Usa <id>`.
String _etiquetaUsar(String appliance) {
  final etiqueta = _etiquetasAparato[appliance];
  if (etiqueta == null) return 'Usa $appliance';
  return 'Enciende $etiqueta';
}

/// Nombre amable de un aparato para el resumen, p. ej. "el horno".
String _nombreAparato(String appliance) =>
    _etiquetasAparato[appliance] ?? appliance;

/// Genera un resumen cercano en español de la línea de tiempo, estilo:
/// "Enciende el horno una vez para lasaña y pollo (40 min). En total, unos 55
/// minutos con todo solapado." SIN usar jamás 'IA'/'AI'/'Inteligencia
/// Artificial'. Función PURA para poder testearla con datos fijos.
String resumenTimeline(TimelinePlan plan) {
  if (plan.isEmpty) {
    return 'No hay nada que cocinar todavía en este plan de cocina.';
  }

  final frases = <String>[];

  // Destacamos los bloques de cocción agrupados (lo más útil del modo cocina).
  for (final step in plan.steps) {
    if (!step.isPrep && step.agrupaVariasRecetas) {
      frases.add(
        'Enciende ${_nombreAparato(step.appliance)} una vez para '
        '${_unirConY(step.recipeTitles)} (${step.durationMinutes} min).',
      );
    }
  }

  // Pasos que pueden solaparse: avisamos de que se aprovecha el tiempo muerto.
  final paralelos = plan.steps.where((s) => s.canRunInParallel).length;
  if (paralelos > 0) {
    frases.add(
      'Mientras tanto, adelanta $paralelos '
      '${paralelos == 1 ? 'preparación' : 'preparaciones'} en paralelo.',
    );
  }

  final total = plan.totalEstimatedMinutes;
  frases.add(
    'En total, unos $total ${total == 1 ? 'minuto' : 'minutos'} '
    'con todo bien solapado.',
  );

  return frases.join(' ');
}

/// Une una lista con comas y una "y" final: ["a","b","c"] -> "a, b y c".
String _unirConY(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  final todosMenosUltimo = items.sublist(0, items.length - 1);
  return '${todosMenosUltimo.join(', ')} y ${items.last}';
}

/// Compara dos listas por elementos en orden.
bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
