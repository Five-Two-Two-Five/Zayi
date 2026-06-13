class Purchase {
  final int? id;
  final int productId;
  final int supplierId;
  final int crates;
  final int remainingEggs;
  final double buyingPricePerCrate;
  final double transportCost;
  final double otherCost;
  final String? otherCostDescription;
  final double totalCost;
  final String? batchNumber;
  final String notes;
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

  Purchase({
    this.id,
    this.productId = 1,
    required this.supplierId,
    required this.crates,
    required this.remainingEggs,
    required this.buyingPricePerCrate,
    required this.transportCost,
    required this.otherCost,
    this.otherCostDescription,
    required this.totalCost,
    this.batchNumber,
    required this.notes,
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

  double get pricePerEgg => (totalCost / (crates * 30));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'supplier_id': supplierId,
      'trays': crates,
      'remaining_eggs': remainingEggs,
      'buying_price_per_tray': buyingPricePerCrate,
      'transport_cost': transportCost,
      'other_cost': otherCost,
      'other_cost_description': otherCostDescription,
      'total_cost': totalCost,
      'batch_number': batchNumber,
      'notes': notes,
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

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      productId: map['product_id'] ?? 1,
      supplierId: map['supplier_id'],
      crates: map['trays'] ?? 0,
      remainingEggs: map['remaining_eggs'] ?? 0,
      buyingPricePerCrate: (map['buying_price_per_tray'] as num?)?.toDouble() ?? 0.0,
      transportCost: (map['transport_cost'] as num?)?.toDouble() ?? 0.0,
      otherCost: (map['other_cost'] as num?)?.toDouble() ?? 0.0,
      otherCostDescription: map['other_cost_description'],
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0.0,
      batchNumber: map['batch_number'],
      notes: map['notes'] ?? '',
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

  Purchase copyWith({
    int? id,
    int? productId,
    int? supplierId,
    int? crates,
    int? remainingEggs,
    double? buyingPricePerCrate,
    double? transportCost,
    double? otherCost,
    String? otherCostDescription,
    double? totalCost,
    String? batchNumber,
    String? notes,
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
    return Purchase(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      crates: crates ?? this.crates,
      remainingEggs: remainingEggs ?? this.remainingEggs,
      buyingPricePerCrate: buyingPricePerCrate ?? this.buyingPricePerCrate,
      transportCost: transportCost ?? this.transportCost,
      otherCost: otherCost ?? this.otherCost,
      otherCostDescription: otherCostDescription ?? this.otherCostDescription,
      totalCost: totalCost ?? this.totalCost,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
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
