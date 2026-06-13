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
  final String currencyCode;
  final double exchangeRate;
  final String paymentMethod;
  final String? uuid;
  final DateTime? lastUpdated;
  final bool isSynced;
  final bool isDeleted;

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
    this.currencyCode = 'USD',
    this.exchangeRate = 1.0,
    this.paymentMethod = 'Other',
    this.uuid,
    this.lastUpdated,
    this.isSynced = false,
    this.isDeleted = false,
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
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'payment_method': paymentMethod,
      'uuid': uuid,
      'last_updated': lastUpdated?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      expenseType: map['expense_type'] ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      employeeName: map['employee_name'],
      extraDetails: map['extra_details'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      currencyCode: map['currency_code'] ?? 'USD',
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      paymentMethod: map['payment_method'] ?? 'Other',
      uuid: map['uuid'],
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      isSynced: (map['is_synced'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  Expense copyWith({
    int? id,
    String? expenseType,
    double? amount,
    String? description,
    String? employeeName,
    String? extraDetails,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    String? currencyCode,
    double? exchangeRate,
    String? paymentMethod,
    String? uuid,
    DateTime? lastUpdated,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Expense(
      id: id ?? this.id,
      expenseType: expenseType ?? this.expenseType,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      employeeName: employeeName ?? this.employeeName,
      extraDetails: extraDetails ?? this.extraDetails,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      uuid: uuid ?? this.uuid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
