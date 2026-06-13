class FixedAsset {
  final int? id;
  final String name;
  final double purchasePrice;
  final DateTime purchaseDate;
  final int usefulLifeMonths;
  final double residualValue;
  final String notes;
  final String currencyCode;
  final double exchangeRate;
  final String paymentMethod;
  final String? uuid;
  final DateTime? lastUpdated;
  final bool isSynced;
  final bool isDeleted;

  FixedAsset({
    this.id,
    required this.name,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.usefulLifeMonths,
    required this.residualValue,
    required this.notes,
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
      'name': name,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate.toIso8601String(),
      'useful_life_months': usefulLifeMonths,
      'residual_value': residualValue,
      'notes': notes,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'payment_method': paymentMethod,
      'uuid': uuid,
      'last_updated': lastUpdated?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory FixedAsset.fromMap(Map<String, dynamic> map) {
    return FixedAsset(
      id: map['id'],
      name: map['name'] ?? '',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: map['purchase_date'] != null ? DateTime.parse(map['purchase_date']) : DateTime.now(),
      usefulLifeMonths: map['useful_life_months'] ?? 12,
      residualValue: (map['residual_value'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      currencyCode: map['currency_code'] ?? 'USD',
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      paymentMethod: map['payment_method'] ?? 'Other',
      uuid: map['uuid'],
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      isSynced: (map['is_synced'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  FixedAsset copyWith({
    int? id,
    String? name,
    double? purchasePrice,
    DateTime? purchaseDate,
    int? usefulLifeMonths,
    double? residualValue,
    String? notes,
    String? currencyCode,
    double? exchangeRate,
    String? paymentMethod,
    String? uuid,
    DateTime? lastUpdated,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return FixedAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      usefulLifeMonths: usefulLifeMonths ?? this.usefulLifeMonths,
      residualValue: residualValue ?? this.residualValue,
      notes: notes ?? this.notes,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      uuid: uuid ?? this.uuid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  double get monthlyDepreciation {
    if (usefulLifeMonths <= 0) return 0.0;
    // Normalize purchase price and residual value to base currency
    final normalizedPurchasePrice = purchasePrice * exchangeRate;
    final normalizedResidualValue = residualValue * exchangeRate;
    return (normalizedPurchasePrice - normalizedResidualValue) / usefulLifeMonths;
  }

  double get accumulatedDepreciation {
    final monthsSincePurchase = DateTime.now().difference(purchaseDate).inDays / 30;
    if (monthsSincePurchase <= 0) return 0.0;
    final totalDepreciation = monthlyDepreciation * monthsSincePurchase;
    final normalizedPurchasePrice = purchasePrice * exchangeRate;
    final normalizedResidualValue = residualValue * exchangeRate;
    
    return totalDepreciation > (normalizedPurchasePrice - normalizedResidualValue) 
        ? (normalizedPurchasePrice - normalizedResidualValue) 
        : totalDepreciation;
  }

  double get bookValue => (purchasePrice * exchangeRate) - accumulatedDepreciation;
}
