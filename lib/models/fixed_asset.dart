class FixedAsset {
  final int? id;
  final String name;
  final double purchasePrice;
  final DateTime purchaseDate;
  final int usefulLifeMonths;
  final double residualValue;
  final String notes;

  FixedAsset({
    this.id,
    required this.name,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.usefulLifeMonths,
    required this.residualValue,
    required this.notes,
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
    );
  }

  double get monthlyDepreciation {
    if (usefulLifeMonths <= 0) return 0.0;
    return (purchasePrice - residualValue) / usefulLifeMonths;
  }

  double get accumulatedDepreciation {
    final monthsSincePurchase = DateTime.now().difference(purchaseDate).inDays / 30;
    if (monthsSincePurchase <= 0) return 0.0;
    final totalDepreciation = monthlyDepreciation * monthsSincePurchase;
    return totalDepreciation > (purchasePrice - residualValue) 
        ? (purchasePrice - residualValue) 
        : totalDepreciation;
  }

  double get bookValue => purchasePrice - accumulatedDepreciation;
}
