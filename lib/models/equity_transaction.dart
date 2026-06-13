enum EquityType {
  contribution,
  drawing
}

class EquityTransaction {
  final int? id;
  final EquityType type;
  final double amount;
  final String notes;
  final DateTime createdAt;
  final String currencyCode;
  final double exchangeRate;
  final String paymentMethod;
  final String? uuid;
  final DateTime? lastUpdated;
  final bool isSynced;
  final bool isDeleted;

  EquityTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.notes,
    required this.createdAt,
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
      'type': type == EquityType.contribution ? 'CONTRIBUTION' : 'DRAWING',
      'amount': amount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'payment_method': paymentMethod,
      'uuid': uuid,
      'last_updated': lastUpdated?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory EquityTransaction.fromMap(Map<String, dynamic> map) {
    return EquityTransaction(
      id: map['id'],
      type: map['type'] == 'CONTRIBUTION' ? EquityType.contribution : EquityType.drawing,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      currencyCode: map['currency_code'] ?? 'USD',
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      paymentMethod: map['payment_method'] ?? 'Other',
      uuid: map['uuid'],
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      isSynced: (map['is_synced'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  EquityTransaction copyWith({
    int? id,
    EquityType? type,
    double? amount,
    String? notes,
    DateTime? createdAt,
    String? currencyCode,
    double? exchangeRate,
    String? paymentMethod,
    String? uuid,
    DateTime? lastUpdated,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return EquityTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
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
