class Sale {
  final int? id;
  final int customerId;
  final int cratesSold;
  final double sellingPricePerCrate;
  final double delivery_cost;
  final double employee_cost;
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
    required this.sellingPricePerCrate,
    required this.delivery_cost,
    required this.employee_cost,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'trays_sold': cratesSold,
      'selling_price_per_tray': sellingPricePerCrate,
      'delivery_cost': delivery_cost,
      'employee_cost': employee_cost,
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
      sellingPricePerCrate: (map['selling_price_per_tray'] as num).toDouble(),
      delivery_cost: (map['delivery_cost'] as num).toDouble(),
      employee_cost: (map['employee_cost'] as num).toDouble(),
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
}
