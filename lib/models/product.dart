class Product {
  final int? id;
  final String name;
  final String unitName; // e.g., "Tray", "Full Chicken"
  final String? subUnitName; // e.g., "Egg", null for Chickens
  final int subUnitsPerUnit; // e.g., 30 for Eggs, 1 for Chickens
  final String? icon;

  Product({
    this.id,
    required this.name,
    required this.unitName,
    this.subUnitName,
    this.subUnitsPerUnit = 1,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit_name': unitName,
      'sub_unit_name': subUnitName,
      'sub_units_per_unit': subUnitsPerUnit,
      'icon': icon,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      unitName: map['unit_name'] ?? '',
      subUnitName: map['sub_unit_name'],
      subUnitsPerUnit: map['sub_units_per_unit'] ?? 1,
      icon: map['icon'],
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? unitName,
    String? subUnitName,
    int? subUnitsPerUnit,
    String? icon,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unitName: unitName ?? this.unitName,
      subUnitName: subUnitName ?? this.subUnitName,
      subUnitsPerUnit: subUnitsPerUnit ?? this.subUnitsPerUnit,
      icon: icon ?? this.icon,
    );
  }
}
