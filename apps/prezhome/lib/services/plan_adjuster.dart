/// Cerebro del plan "vivo": cuando una comida se marca como "hoy como fuera"
/// (skipped), su plato NO se pierde, sino que se recoloca a otro hueco del
/// MISMO tipo de comida más adelante en la semana.
///
/// Toda la lógica de este archivo es PURA: no depende de Flutter ni de
/// Supabase, solo de dart:core. Así se puede testear con datos fijos y el
/// resultado es determinista.
///
/// Filosofía (de Tessa): flexibilidad por encima de perfección. Si no hay
/// hueco posterior para recolocar el plato, no pasa nada: no se recoloca y no
/// se inventa nada raro (mejor repetir o dejarlo).
library;

/// Representación ligera de una entrada del plan para la lógica pura.
///
/// Es un espejo mínimo de `MealPlanEntry` pero sin dependencias de modelos de
/// la app, para que el "cerebro" sea totalmente aislado y testeable.
class PlanSlot {
  /// Identificador estable del hueco (p.ej. el id de la fila en Supabase).
  /// Puede ser null para huecos "virtuales" (días sin esa comida todavía).
  final String? id;

  /// Fecha del hueco (solo cuenta año/mes/día).
  final DateTime date;

  /// Tipo de comida: breakfast/lunch/dinner/snack/dessert.
  final String mealType;

  /// Receta colocada en el hueco. null = hueco libre (sin plato activo).
  final String? recipeId;

  /// true = se come fuera ese día esa comida (plato recolocado o pendiente).
  final bool skipped;

  const PlanSlot({
    this.id,
    required this.date,
    required this.mealType,
    this.recipeId,
    this.skipped = false,
  });

  PlanSlot copyWith({
    String? recipeId,
    bool clearRecipe = false,
    bool? skipped,
  }) {
    return PlanSlot(
      id: id,
      date: date,
      mealType: mealType,
      recipeId: clearRecipe ? null : (recipeId ?? this.recipeId),
      skipped: skipped ?? this.skipped,
    );
  }

  /// Clave día (año-mes-día) para comparar fechas sin la parte horaria.
  DateTime get _day => DateTime(date.year, date.month, date.day);
}

/// Resultado de un reajuste: el plan actualizado y un mensaje cozy de Miau.
class PlanAdjustment {
  /// Plan completo tras el reajuste (misma longitud y orden que la entrada).
  final List<PlanSlot> slots;

  /// Receta que se movió (si hubo movimiento), para construir mensajes.
  final String? movedRecipeId;

  /// Fecha destino donde se recolocó el plato (null si no hubo recolocación).
  final DateTime? movedToDate;

  const PlanAdjustment({
    required this.slots,
    this.movedRecipeId,
    this.movedToDate,
  });
}

/// Lógica pura de reajuste del plan al "comer fuera" / reactivar una comida.
class PlanAdjuster {
  const PlanAdjuster();

  /// Recoloca el plato de la comida marcada como "fuera".
  ///
  /// [slots] es el plan de la semana. [targetId] identifica el hueco que se
  /// acaba de marcar como skipped. Devuelve el plan reajustado y los datos del
  /// movimiento para el mensaje de Miau.
  ///
  /// Regla: para el hueco objetivo con receta R y tipo T, busca el PRIMER hueco
  /// POSTERIOR en el tiempo del mismo tipo T que esté libre (sin receta y sin
  /// estar marcado como fuera). Mueve R allí y deja el hueco objetivo "como
  /// fuera" sin plato activo. Si no hay hueco posterior libre, deja la receta
  /// sin recolocar (no se pierde el dato, pero el plato no viaja).
  PlanAdjustment adjustForSkipped(List<PlanSlot> slots, String targetId) {
    final result = List<PlanSlot>.from(slots);
    final targetIndex = result.indexWhere((s) => s.id == targetId);
    if (targetIndex < 0) {
      return PlanAdjustment(slots: result);
    }

    final target = result[targetIndex];
    final recipeId = target.recipeId;

    // Marcamos siempre el hueco objetivo como "fuera" (idempotente).
    // El plato deja de estar activo en ese día.
    result[targetIndex] = target.copyWith(skipped: true, clearRecipe: true);

    // Sin receta que mover: solo queda marcado como fuera.
    if (recipeId == null) {
      return PlanAdjustment(slots: result);
    }

    // Buscar el primer hueco posterior libre del MISMO tipo de comida.
    final targetDay = target._day;
    int bestIndex = -1;
    DateTime? bestDay;
    for (var i = 0; i < result.length; i++) {
      final slot = result[i];
      if (i == targetIndex) continue;
      if (slot.mealType != target.mealType) continue;
      final day = slot._day;
      if (!day.isAfter(targetDay)) continue; // solo días posteriores
      final isFree = slot.recipeId == null && !slot.skipped;
      if (!isFree) continue;
      if (bestDay == null || day.isBefore(bestDay)) {
        bestDay = day;
        bestIndex = i;
      }
    }

    // No hay hueco: flexibilidad, no se recoloca (no pasa nada).
    if (bestIndex < 0) {
      return PlanAdjustment(slots: result);
    }

    final destination = result[bestIndex];
    result[bestIndex] = destination.copyWith(recipeId: recipeId);
    return PlanAdjustment(
      slots: result,
      movedRecipeId: recipeId,
      movedToDate: bestDay,
    );
  }

  /// Reactiva una comida que estaba marcada como "fuera".
  ///
  /// Semántica elegida (documentada): al reactivar, el hueco vuelve a quedar
  /// activo (skipped = false). No intentamos "deshacer" un movimiento previo
  /// porque la lógica pura no guarda historial; simplemente dejamos el día
  /// disponible de nuevo para que la usuaria o el planificador lo rellenen.
  /// Si el hueco todavía conserva una receta, se mantiene.
  PlanAdjustment reactivate(List<PlanSlot> slots, String targetId) {
    final result = List<PlanSlot>.from(slots);
    final index = result.indexWhere((s) => s.id == targetId);
    if (index < 0) {
      return PlanAdjustment(slots: result);
    }
    result[index] = result[index].copyWith(skipped: false);
    return PlanAdjustment(slots: result);
  }
}

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

/// Construye el mensaje cozy de Miau a partir de un reajuste.
///
/// Función PURA y separada de la UI para poder testearla. [recipeTitle] es el
/// título legible de la receta (si se conoce); si es null se usa "el plato".
///
/// - Con recolocación: "Movido {receta} al {díaSemana}".
/// - Sin recolocación: "Lo dejo para otro momento".
String miauMoveMessage(PlanAdjustment adjustment, {String? recipeTitle}) {
  final destino = adjustment.movedToDate;
  if (adjustment.movedRecipeId == null || destino == null) {
    return 'Lo dejo para otro momento';
  }
  final receta = (recipeTitle != null && recipeTitle.trim().isNotEmpty)
      ? recipeTitle.trim()
      : 'el plato';
  final dia = _diasSemana[destino.weekday - 1];
  return 'Movido $receta al $dia';
}
