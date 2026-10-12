class HomeTask {
  final String id;
  final String homeId;
  final String title;
  final String? notes;
  final int points;
  // Esfuerzo estimado de la tarea (informativo). Independiente de 'points',
  // que es el valor que suma al marcador al completarla.
  final int effortPoints;
  // once | daily | weekly | custom_interval | custom_weekdays
  final String recurrence;
  final int? intervalCount; // para custom_interval (ej. 3)
  final String? intervalUnit; // 'day' | 'week'
  final List<int> weekdays; // para custom_weekdays: 1=Lun..7=Dom
  final String? assignedTo; // user id, o null = cualquiera
  final DateTime? dueDate;
  final String? dueTime; // hora "HH:mm" opcional
  // Proxima fecha en la que la tarea debe volver a aparecer como pendiente.
  // Para 'once' coincide con dueDate; para recurrentes la avanzamos al
  // completarla con [computeNextDue]. Puede ser null (tarea sin fecha).
  final DateTime? nextDue;
  final DateTime? lastCompletedAt;
  final bool isDone;
  final String? completedBy;
  final DateTime? completedAt;

  HomeTask({
    required this.id,
    required this.homeId,
    required this.title,
    this.notes,
    this.points = 10,
    this.effortPoints = 10,
    this.recurrence = 'once',
    this.intervalCount,
    this.intervalUnit,
    this.weekdays = const [],
    this.assignedTo,
    this.dueDate,
    this.dueTime,
    this.nextDue,
    this.lastCompletedAt,
    this.isDone = false,
    this.completedBy,
    this.completedAt,
  });

  factory HomeTask.fromMap(Map<String, dynamic> map) {
    final rawWeekdays = map['weekdays'];
    return HomeTask(
      id: map['id'],
      homeId: map['home_id'],
      title: map['title'],
      notes: map['notes'],
      points: map['points'] ?? 10,
      // Filas antiguas no tienen la columna effort_points: caemos a points y
      // en ultimo caso a 10 para mantener fromMap tolerante a nulos.
      effortPoints: map['effort_points'] ?? map['points'] ?? 10,
      recurrence: map['recurrence'] ?? 'once',
      intervalCount: map['interval_count'],
      intervalUnit: map['interval_unit'],
      weekdays: rawWeekdays is List
          ? rawWeekdays.map((e) => (e as num).toInt()).toList()
          : const [],
      assignedTo: map['assigned_to'],
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'])
          : null,
      dueTime: _shortTime(map['due_time']),
      nextDue: map['next_due'] != null
          ? DateTime.tryParse(map['next_due'])
          : null,
      lastCompletedAt: map['last_completed_at'] != null
          ? DateTime.tryParse(map['last_completed_at'])
          : null,
      isDone: map['is_done'] ?? false,
      completedBy: map['completed_by'],
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toInsertMap({required String createdBy}) {
    return {
      'home_id': homeId,
      'title': title,
      'notes': notes,
      'points': points,
      'effort_points': effortPoints,
      'recurrence': recurrence,
      'interval_count': recurrence == 'custom_interval' ? intervalCount : null,
      'interval_unit': recurrence == 'custom_interval' ? intervalUnit : null,
      'weekdays': recurrence == 'custom_weekdays' ? weekdays : null,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String().split('T').first,
      // La primera aparicion de una tarea nueva es su fecha limite (si la hay).
      // Para recurrentes sin fecha, next_due = hoy para que entre en el flujo.
      'next_due': (dueDate ?? (recurrence == 'once' ? null : DateTime.now()))
          ?.toIso8601String()
          .split('T')
          .first,
      'due_time': dueTime, // "HH:mm" o null
      'created_by': createdBy,
    };
  }

  /// Datos de reprogramacion al completar una recurrente. Avanza due_date y
  /// next_due a [next], marca la ultima vez completada (y quien la hizo) y deja
  /// is_done=false para que la tarea reaparezca en su proxima ocurrencia. No
  /// toca assigned_to: el responsable de una recurrente se conserva.
  static Map<String, dynamic> rescheduleMap({
    required DateTime next,
    required String completedBy,
  }) {
    final nextKey = DateTime(
      next.year,
      next.month,
      next.day,
    ).toIso8601String().split('T').first;
    final nowIso = DateTime.now().toIso8601String();
    return {
      'due_date': nextKey,
      'next_due': nextKey,
      'is_done': false,
      'completed_by': completedBy,
      'completed_at': nowIso,
      'last_completed_at': nowIso,
    };
  }

  /// Datos al completar una tarea puntual ('once'): se marca como hecha.
  static Map<String, dynamic> completeOnceMap({required String completedBy}) {
    final nowIso = DateTime.now().toIso8601String();
    return {
      'is_done': true,
      'completed_by': completedBy,
      'completed_at': nowIso,
      'last_completed_at': nowIso,
    };
  }

  /// Calcula la SIGUIENTE fecha de aparicion de la tarea a partir de [from]
  /// (normalizada a dia, sin hora) segun su recurrencia:
  ///   - 'once'            -> null (no se reprograma, es puntual).
  ///   - 'daily'           -> [from] + 1 dia.
  ///   - 'weekly'          -> [from] + 7 dias.
  ///   - 'custom_interval' -> [from] + intervalCount * (dia|semana) segun
  ///                          intervalUnit ('week' => *7 dias).
  ///   - 'custom_weekdays' -> el proximo dia marcado en [weekdays] (1=Lun..
  ///                          7=Dom) ESTRICTAMENTE posterior a [from], con wrap
  ///                          a la semana siguiente (de domingo a lunes). Si no
  ///                          hay dias marcados, devuelve null.
  /// Metodo puro y testeable: solo depende de los campos de recurrencia y de
  /// [from]; no toca red ni estado.
  DateTime? computeNextDue(DateTime from) {
    final base = DateTime(from.year, from.month, from.day);
    switch (recurrence) {
      case 'once':
        return null;
      case 'daily':
        return base.add(const Duration(days: 1));
      case 'weekly':
        return base.add(const Duration(days: 7));
      case 'custom_interval':
        final n = (intervalCount == null || intervalCount! < 1)
            ? 1
            : intervalCount!;
        final days = intervalUnit == 'week' ? n * 7 : n;
        return base.add(Duration(days: days));
      case 'custom_weekdays':
        if (weekdays.isEmpty) return null;
        final marked = weekdays.toSet();
        // Buscamos el proximo dia (1..7) marcado dentro de los proximos 7 dias.
        for (var i = 1; i <= 7; i++) {
          final candidate = base.add(Duration(days: i));
          // DateTime.weekday: 1=Lun..7=Dom, mismo criterio que weekdays.
          if (marked.contains(candidate.weekday)) return candidate;
        }
        return null;
      default:
        return null;
    }
  }

  /// Normaliza una hora que puede venir como "20:00:00" a "20:00".
  static String? _shortTime(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    final parts = s.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    return s;
  }

  static const Map<String, String> recurrenceLabels = {
    'once': 'Puntual',
    'daily': 'Cada día',
    'weekly': 'Cada semana',
    'custom_interval': 'Cada X días/semanas',
    'custom_weekdays': 'Días concretos',
  };

  static const List<String> weekdayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const List<String> weekdayLong = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// Predicado puro: una tarea no tiene responsable asignado cuando
  /// assigned_to == null (la puede hacer cualquiera del hogar).
  bool get isInPool => assignedTo == null;

  /// Etiqueta legible de la recurrencia (para mostrar en la lista).
  String get recurrenceLabel {
    switch (recurrence) {
      case 'custom_interval':
        final n = intervalCount ?? 1;
        final unit = intervalUnit == 'week'
            ? (n == 1 ? 'semana' : 'semanas')
            : (n == 1 ? 'día' : 'días');
        return 'Cada $n $unit';
      case 'custom_weekdays':
        if (weekdays.isEmpty) return 'Días concretos';
        final sorted = [...weekdays]..sort();
        return sorted.map((d) => weekdayShort[d - 1]).join(' ');
      default:
        return recurrenceLabels[recurrence] ?? 'Puntual';
    }
  }
}
