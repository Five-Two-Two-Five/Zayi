class Expense {
  final int? id;
  final String expenseType;
  final double amount;
  final String description;
  final DateTime createdAt;
  final double latitude;
  final double longitude;

  Expense({
    this.id,
    required this.expenseType,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_type': expenseType,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      expenseType: map['expense_type'],
      amount: map['amount'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
