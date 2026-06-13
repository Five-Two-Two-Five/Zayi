class Product {
  final int? id;
  final String name;
  final String unitName; // e.g., "Tray", "Full Chicken"
  final String? subUnitName; // e.g., "Egg", null for Chickens
  final int subUnitsPerUnit; // e.g., 30 for Eggs, 1 for Chickens
  final String? icon;
  final String? uuid;
  final DateTime? lastUpdated;
  final bool isSynced;
  final bool isDeleted;

  Product({
    this.id,
    required this.name,
    required this.unitName,
    this.subUnitName,
    this.subUnitsPerUnit = 1,
    this.icon,
    this.uuid,
    this.lastUpdated,
    this.isSynced = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit_name': unitName,
      'sub_unit_name': subUnitName,
      'sub_units_per_unit': subUnitsPerUnit,
      'icon': icon,
      'uuid': uuid,
      'last_updated': lastUpdated?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
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
      uuid: map['uuid'],
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      isSynced: (map['is_synced'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? unitName,
    String? subUnitName,
    int? subUnitsPerUnit,
    String? icon,
    String? uuid,
    DateTime? lastUpdated,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unitName: unitName ?? this.unitName,
      subUnitName: subUnitName ?? this.subUnitName,
      subUnitsPerUnit: subUnitsPerUnit ?? this.subUnitsPerUnit,
      icon: icon ?? this.icon,
      uuid: uuid ?? this.uuid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
