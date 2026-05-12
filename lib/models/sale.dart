class Sale {
  final int? id;
  final int customerId;
  final int traysSold;
  final double sellingPricePerTray;
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
    required this.traysSold,
    required this.sellingPricePerTray,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'trays_sold': traysSold,
      'selling_price_per_tray': sellingPricePerTray,
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
      traysSold: map['trays_sold'],
      sellingPricePerTray: map['selling_price_per_tray'],
      deliveryCost: map['delivery_cost'],
      employeeCost: map['employee_cost'],
      totalRevenue: map['total_revenue'],
      totalCost: map['total_cost'],
      profit: map['profit'],
      amountPaid: map['amount_paid'],
      balanceDue: map['balance_due'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
