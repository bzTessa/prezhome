/// Centro de RECORDATORIOS INTELIGENTES (sin IA): junta en una sola lista
/// priorizada lo que la usuaria tiene que hacer hoy/mañana en todas las áreas
/// (cocina, congelador, caducidades, tareas, compra). Es LÓGICA PURA: recibe
/// datos ya cargados y devuelve los recordatorios ordenados por urgencia, para
/// poder testearla con fechas fijas y no gastar nada de IA ni red.
library;

/// Tipo/área de un recordatorio (para icono y color en la UI).
enum ReminderKind { congelador, caducidad, cocina, tarea, compra }

/// Urgencia, para ordenar y colorear.
enum ReminderUrgency { urgente, hoy, pronto }

/// Un recordatorio concreto que mostrar a la usuaria.
class Reminder {
  final ReminderKind kind;
  final ReminderUrgency urgency;
  final String text;

  const Reminder({
    required this.kind,
    required this.urgency,
    required this.text,
  });
}

/// Datos de entrada mínimos (espejos reducidos de los modelos de la app) para
/// no acoplar el servicio con Flutter/Supabase.

/// Alimento del inventario con su caducidad (en días desde hoy; negativo =
/// caducado) y ubicación.
class ReminderStockItem {
  final String name;
  final int? daysUntilExpiry;
  final bool isFrozen; // está en el congelador
  const ReminderStockItem({
    required this.name,
    this.daysUntilExpiry,
    this.isFrozen = false,
  });
}

/// Algo que hay que SACAR del congelador: nombre + días hasta sacarlo (0 = hoy,
/// 1 = mañana; negativo = ya debería estar fuera).
class ReminderTakeOut {
  final String name;
  final int daysUntilTakeOut;
  const ReminderTakeOut({required this.name, required this.daysUntilTakeOut});
}

/// Genera la lista de recordatorios a partir de los datos del día.
///
/// Parámetros (todos ya calculados por quien llama):
///  - [mealsToday]: títulos de las comidas planificadas para hoy (no saltadas).
///  - [stock]: alimentos del inventario con días hasta caducar.
///  - [takeOuts]: cosas a sacar del congelador (con días hasta sacarlas).
///  - [tasksToday]: títulos de tareas que vencen hoy o están vencidas.
///  - [pendingShopping]: nº de artículos pendientes en la lista de la compra.
///
/// Reglas de urgencia:
///  - caducado / debería estar ya fuera del congelador / tarea vencida -> urgente
///  - caduca hoy o mañana / sacar hoy o mañana / cocina de hoy / tarea de hoy -> hoy
///  - caduca en <=3 días -> pronto
List<Reminder> buildReminders({
  required List<String> mealsToday,
  required List<ReminderStockItem> stock,
  required List<ReminderTakeOut> takeOuts,
  required List<String> tasksToday,
  required int pendingShopping,
}) {
  final out = <Reminder>[];

  // ❄️ Sacar del congelador.
  for (final t in takeOuts) {
    if (t.daysUntilTakeOut <= 0) {
      out.add(
        Reminder(
          kind: ReminderKind.congelador,
          urgency: t.daysUntilTakeOut < 0
              ? ReminderUrgency.urgente
              : ReminderUrgency.hoy,
          text: t.daysUntilTakeOut < 0
              ? 'Saca ${t.name} del congelador (ya tocaba)'
              : 'Saca ${t.name} del congelador para mañana',
        ),
      );
    } else if (t.daysUntilTakeOut == 1) {
      out.add(
        Reminder(
          kind: ReminderKind.congelador,
          urgency: ReminderUrgency.pronto,
          text: 'Mañana saca ${t.name} del congelador',
        ),
      );
    }
  }

  // ⏰ Caducidades (solo lo que no está en el congelador: eso tiene su propio
  // aviso de "sacar"). Avisa de caducado, hoy/mañana y <=3 días.
  for (final s in stock) {
    final d = s.daysUntilExpiry;
    if (d == null || s.isFrozen) continue;
    if (d < 0) {
      out.add(
        Reminder(
          kind: ReminderKind.caducidad,
          urgency: ReminderUrgency.urgente,
          text: '${s.name} ha caducado',
        ),
      );
    } else if (d == 0) {
      out.add(
        Reminder(
          kind: ReminderKind.caducidad,
          urgency: ReminderUrgency.hoy,
          text: 'Usa ${s.name} hoy (caduca)',
        ),
      );
    } else if (d == 1) {
      out.add(
        Reminder(
          kind: ReminderKind.caducidad,
          urgency: ReminderUrgency.hoy,
          text: 'Usa ${s.name} pronto (caduca mañana)',
        ),
      );
    } else if (d <= 3) {
      out.add(
        Reminder(
          kind: ReminderKind.caducidad,
          urgency: ReminderUrgency.pronto,
          text: '${s.name} caduca en $d días',
        ),
      );
    }
  }

  // 🍳 Cocina de hoy.
  for (final m in mealsToday) {
    out.add(
      Reminder(
        kind: ReminderKind.cocina,
        urgency: ReminderUrgency.hoy,
        text: 'Hoy toca: $m',
      ),
    );
  }

  // ✅ Tareas de hoy / vencidas.
  for (final t in tasksToday) {
    out.add(
      Reminder(kind: ReminderKind.tarea, urgency: ReminderUrgency.hoy, text: t),
    );
  }

  // 🛒 Compra pendiente (un único recordatorio resumen).
  if (pendingShopping > 0) {
    out.add(
      Reminder(
        kind: ReminderKind.compra,
        urgency: ReminderUrgency.pronto,
        text: pendingShopping == 1
            ? 'Te queda 1 cosa por comprar'
            : 'Te quedan $pendingShopping cosas por comprar',
      ),
    );
  }

  // Orden: por urgencia (urgente < hoy < pronto). Estable dentro de cada nivel.
  int rank(ReminderUrgency u) => switch (u) {
    ReminderUrgency.urgente => 0,
    ReminderUrgency.hoy => 1,
    ReminderUrgency.pronto => 2,
  };
  out.sort((a, b) => rank(a.urgency).compareTo(rank(b.urgency)));
  return out;
}
