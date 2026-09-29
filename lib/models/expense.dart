class Expense {
  final String id;
  final String homeId;
  final double amount;
  final String category; // Supermercado | Hogar | Ocio | Otros
  final String? store;
  final String? note;
  final DateTime spentOn;
  final String? ticketPath;

  Expense({
    required this.id,
    required this.homeId,
    required this.amount,
    this.category = 'Supermercado',
    this.store,
    this.note,
    required this.spentOn,
    this.ticketPath,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      homeId: map['home_id'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? 'Otros',
      store: map['store'],
      note: map['note'],
      spentOn: DateTime.parse(map['spent_on']),
      ticketPath: map['ticket_path'],
    );
  }

  Map<String, dynamic> toInsertMap({required String createdBy}) {
    return {
      'home_id': homeId,
      'amount': amount,
      'category': category,
      'store': store,
      'note': note,
      'spent_on': spentOn.toIso8601String().split('T').first,
      'ticket_path': ticketPath,
      'created_by': createdBy,
    };
  }

  static const List<String> categories = [
    'Supermercado',
    'Hogar',
    'Ocio',
    'Otros',
  ];
}
