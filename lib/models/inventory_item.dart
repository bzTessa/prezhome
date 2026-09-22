class InventoryItem {
  final String id;
  final String homeId;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final DateTime? expirationDate;

  InventoryItem({
    required this.id,
    required this.homeId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expirationDate,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      homeId: map['home_id'],
      name: map['name'],
      category: map['category'],
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
      expirationDate: map['expiration_date'] != null
          ? DateTime.parse(map['expiration_date'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home_id': homeId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiration_date': expirationDate?.toIso8601String().split('T').first,
    };
  }
}