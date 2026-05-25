class Purchase {
  final int? id;
  final int supplierId;
  final int crates;
  final int remainingEggs;
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
    required this.remainingEggs,
    required this.buyingPricePerCrate,
    required this.transportCost,
    required this.otherCost,
    required this.totalCost,
    required this.notes,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  double get pricePerEgg => (totalCost / (crates * 30));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'trays': crates,
      'remaining_eggs': remainingEggs,
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
      remainingEggs: map['remaining_eggs'] ?? 0,
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

  Purchase copyWith({
    int? id,
    int? supplierId,
    int? crates,
    int? remainingEggs,
    double? buyingPricePerCrate,
    double? transportCost,
    double? otherCost,
    double? totalCost,
    String? notes,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      crates: crates ?? this.crates,
      remainingEggs: remainingEggs ?? this.remainingEggs,
      buyingPricePerCrate: buyingPricePerCrate ?? this.buyingPricePerCrate,
      transportCost: transportCost ?? this.transportCost,
      otherCost: otherCost ?? this.otherCost,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
