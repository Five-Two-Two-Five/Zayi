class Sale {
  final int? id;
  final int productId;
  final int customerId;
  final int cratesSold;
  final int eggsSold;
  final double sellingPricePerCrate;
  final double deliveryCost;
  final double employeeCost;
  final double taxRate;
  final double taxAmount;
  final String? taxLabel;
  final bool isTaxInclusive;
  final double totalRevenue;
  final double totalCost;
  final double profit;
  final double amountPaid;
  final double balanceDue;
  final String notes;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final String currencyCode;
  final double exchangeRate;
  final String? uuid;
  final DateTime? lastUpdated;
  final bool isSynced;
  final bool isDeleted;

  Sale({
    this.id,
    this.productId = 1,
    required this.customerId,
    required this.cratesSold,
    required this.eggsSold,
    required this.sellingPricePerCrate,
    required this.deliveryCost,
    required this.employeeCost,
    required this.taxRate,
    required this.taxAmount,
    this.taxLabel,
    this.isTaxInclusive = false,
    required this.totalRevenue,
    required this.totalCost,
    required this.profit,
    required this.amountPaid,
    required this.balanceDue,
    required this.notes,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    this.currencyCode = 'USD',
    this.exchangeRate = 1.0,
    this.uuid,
    this.lastUpdated,
    this.isSynced = false,
    this.isDeleted = false,
  });

  int get totalEggsSold => (cratesSold * 30) + eggsSold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'customer_id': customerId,
      'trays_sold': cratesSold,
      'eggs_sold': eggsSold,
      'selling_price_per_tray': sellingPricePerCrate,
      'delivery_cost': deliveryCost,
      'employee_cost': employeeCost,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'tax_label': taxLabel,
      'is_tax_inclusive': isTaxInclusive ? 1 : 0,
      'total_revenue': totalRevenue,
      'total_cost': totalCost,
      'profit': profit,
      'amount_paid': amountPaid,
      'balance_due': balanceDue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'uuid': uuid,
      'last_updated': lastUpdated?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      productId: map['product_id'] ?? 1,
      customerId: map['customer_id'],
      cratesSold: map['trays_sold'] ?? 0,
      eggsSold: map['eggs_sold'] ?? 0,
      sellingPricePerCrate: (map['selling_price_per_tray'] as num?)?.toDouble() ?? 0.0,
      deliveryCost: (map['delivery_cost'] as num?)?.toDouble() ?? 0.0,
      employeeCost: (map['employee_cost'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      taxLabel: map['tax_label'],
      isTaxInclusive: (map['is_tax_inclusive'] as int?) == 1,
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      currencyCode: map['currency_code'] ?? 'USD',
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      uuid: map['uuid'],
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      isSynced: (map['is_synced'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  Sale copyWith({
    int? id,
    int? productId,
    int? customerId,
    int? cratesSold,
    int? eggsSold,
    double? sellingPricePerCrate,
    double? deliveryCost,
    double? employeeCost,
    double? taxRate,
    double? taxAmount,
    String? taxLabel,
    bool? isTaxInclusive,
    double? totalRevenue,
    double? totalCost,
    double? profit,
    double? amountPaid,
    double? balanceDue,
    String? notes,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    String? currencyCode,
    double? exchangeRate,
    String? uuid,
    DateTime? lastUpdated,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      customerId: customerId ?? this.customerId,
      cratesSold: cratesSold ?? this.cratesSold,
      eggsSold: eggsSold ?? this.eggsSold,
      sellingPricePerCrate: sellingPricePerCrate ?? this.sellingPricePerCrate,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      employeeCost: employeeCost ?? this.employeeCost,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      taxLabel: taxLabel ?? this.taxLabel,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCost: totalCost ?? this.totalCost,
      profit: profit ?? this.profit,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      uuid: uuid ?? this.uuid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
