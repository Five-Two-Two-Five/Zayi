class Sale {
  final int? id;
  final int customerId;
  final int cratesSold;
  final int eggsSold;
  final double sellingPricePerCrate;
  final double deliveryCost;
  final double employeeCost;
  final double totalRevenue;
  final double totalCost;
  final double profit;
  final double amountPaid;
  final double balanceDue;
  final String notes;
  final DateTime createdAt;
  final double latitude;
  final double longitude;

  Sale({
    this.id,
    required this.customerId,
    required this.cratesSold,
    required this.eggsSold,
    required this.sellingPricePerCrate,
    required this.deliveryCost,
    required this.employeeCost,
    required this.totalRevenue,
    required this.totalCost,
    required this.profit,
    required this.amountPaid,
    required this.balanceDue,
    required this.notes,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  int get totalEggsSold => (cratesSold * 30) + eggsSold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'trays_sold': cratesSold,
      'eggs_sold': eggsSold,
      'selling_price_per_tray': sellingPricePerCrate,
      'delivery_cost': deliveryCost,
      'employee_cost': employeeCost,
      'total_revenue': totalRevenue,
      'total_cost': totalCost,
      'profit': profit,
      'amount_paid': amountPaid,
      'balance_due': balanceDue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      customerId: map['customer_id'],
      cratesSold: map['trays_sold'],
      eggsSold: map['eggs_sold'] ?? 0,
      sellingPricePerCrate: (map['selling_price_per_tray'] as num).toDouble(),
      deliveryCost: (map['delivery_cost'] as num).toDouble(),
      employeeCost: (map['employee_cost'] as num).toDouble(),
      totalRevenue: (map['total_revenue'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      profit: (map['profit'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      balanceDue: (map['balance_due'] as num).toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }

  Sale copyWith({
    int? id,
    int? customerId,
    int? cratesSold,
    int? eggsSold,
    double? sellingPricePerCrate,
    double? deliveryCost,
    double? employeeCost,
    double? totalRevenue,
    double? totalCost,
    double? profit,
    double? amountPaid,
    double? balanceDue,
    String? notes,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      cratesSold: cratesSold ?? this.cratesSold,
      eggsSold: eggsSold ?? this.eggsSold,
      sellingPricePerCrate: sellingPricePerCrate ?? this.sellingPricePerCrate,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      employeeCost: employeeCost ?? this.employeeCost,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCost: totalCost ?? this.totalCost,
      profit: profit ?? this.profit,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
