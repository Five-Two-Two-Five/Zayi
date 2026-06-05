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

  EquityTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.notes,
    required this.createdAt,
    this.currencyCode = 'USD',
    this.exchangeRate = 1.0,
    this.paymentMethod = 'Other',
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
    );
  }
}
