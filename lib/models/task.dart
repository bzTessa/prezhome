class HomeTask {
  final String id;
  final String homeId;
  final String title;
  final String? notes;
  final int points;
  final String recurrence; // once | daily | weekly
  final String? assignedTo; // user id, o null = cualquiera
  final DateTime? dueDate;
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
    this.assignedTo,
    this.dueDate,
    this.isDone = false,
    this.completedBy,
    this.completedAt,
  });

  factory HomeTask.fromMap(Map<String, dynamic> map) {
    return HomeTask(
      id: map['id'],
      homeId: map['home_id'],
      title: map['title'],
      notes: map['notes'],
      points: map['points'] ?? 10,
      recurrence: map['recurrence'] ?? 'once',
      assignedTo: map['assigned_to'],
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'])
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
      'recurrence': recurrence,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'created_by': createdBy,
    };
  }

  static const Map<String, String> recurrenceLabels = {
    'once': 'Puntual',
    'daily': 'Cada día',
    'weekly': 'Cada semana',
  };

  String get recurrenceLabel => recurrenceLabels[recurrence] ?? 'Puntual';
}
