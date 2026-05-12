class Purchase {
  final int? id;
  final int supplierId;
  final int trays;
  final double buyingPricePerTray;
  final double transportCost;
  final double otherCost;
  final double totalCost;
  final String notes;
  final DateTime createdAt;
  final double latitude;
  final double longitude;

  Purchase({
    this.id,
    required this.supplierId,
    required this.trays,
    required this.buyingPricePerTray,
    required this.transportCost,
    required this.otherCost,
    required this.totalCost,
    required this.notes,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'trays': trays,
      'buying_price_per_tray': buyingPricePerTray,
      'transport_cost': transportCost,
      'other_cost': otherCost,
      'total_cost': totalCost,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      supplierId: map['supplier_id'],
      trays: map['trays'],
      buyingPricePerTray: map['buying_price_per_tray'],
      transportCost: map['transport_cost'],
      otherCost: map['other_cost'],
      totalCost: map['total_cost'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
