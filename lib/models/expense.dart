class Expense {
  final int? id;
  final String expenseType;
  final double amount;
  final String description;
  final String? employeeName;
  final String? extraDetails;
  final DateTime createdAt;
  final double latitude;
  final double longitude;

  Expense({
    this.id,
    required this.expenseType,
    required this.amount,
    required this.description,
    this.employeeName,
    this.extraDetails,
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
      'employee_name': employeeName,
      'extra_details': extraDetails,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      expenseType: map['expense_type'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      employeeName: map['employee_name'],
      extraDetails: map['extra_details'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
