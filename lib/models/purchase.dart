class Purchase {
  final int? id;
  final int supplierId;
  final int crates;
  final double buyingPricePerCrate;
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
    required this.crates,
    required this.buyingPricePerCrate,
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
      'trays': crates,
      'buying_price_per_tray': buyingPricePerCrate,
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
      crates: map['trays'],
      buyingPricePerCrate: (map['buying_price_per_tray'] as num).toDouble(),
      transportCost: (map['transport_cost'] as num).toDouble(),
      otherCost: (map['other_cost'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
