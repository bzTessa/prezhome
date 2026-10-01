class HomeTask {
  final String id;
  final String homeId;
  final String title;
  final String? notes;
  final int points;
  // once | daily | weekly | custom_interval | custom_weekdays
  final String recurrence;
  final int? intervalCount; // para custom_interval (ej. 3)
  final String? intervalUnit; // 'day' | 'week'
  final List<int> weekdays; // para custom_weekdays: 1=Lun..7=Dom
  final String? assignedTo; // user id, o null = cualquiera
  final DateTime? dueDate;
  final String? dueTime; // hora "HH:mm" opcional
  final bool isDone;
  final String? completedBy;
  final DateTime? completedAt;

  HomeTask({
    required this.id,
    required this.homeId,
    required this.title,
    this.notes,
    this.points = 10,
    this.recurrence = 'once',
    this.intervalCount,
    this.intervalUnit,
    this.weekdays = const [],
    this.assignedTo,
    this.dueDate,
    this.dueTime,
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
      'recurrence': recurrence,
      'interval_count': recurrence == 'custom_interval' ? intervalCount : null,
      'interval_unit': recurrence == 'custom_interval' ? intervalUnit : null,
      'weekdays': recurrence == 'custom_weekdays' ? weekdays : null,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'due_time': dueTime, // "HH:mm" o null
      'created_by': createdBy,
    };
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
