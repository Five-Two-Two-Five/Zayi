class Inventory {
  final int? id;
  final int productId;
  final int cratesIn;
  final int cratesOut;
  final int balance;
  final DateTime createdAt;
  final String? uuid;
  final DateTime? lastUpdated;
  final bool isSynced;
  final bool isDeleted;

  Inventory({
    this.id,
    this.productId = 1,
    required this.cratesIn,
    required this.cratesOut,
    required this.balance,
    required this.createdAt,
    this.uuid,
    this.lastUpdated,
    this.isSynced = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'trays_in': cratesIn,
      'trays_out': cratesOut,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'uuid': uuid,
      'last_updated': lastUpdated?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      id: map['id'],
      productId: map['product_id'] ?? 1,
      cratesIn: map['trays_in'] as int,
      cratesOut: map['trays_out'] as int,
      balance: map['balance'] as int,
      createdAt: DateTime.parse(map['created_at']),
      uuid: map['uuid'],
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      isSynced: (map['is_synced'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  Inventory copyWith({
    int? id,
    int? productId,
    int? cratesIn,
    int? cratesOut,
    int? balance,
    DateTime? createdAt,
    String? uuid,
    DateTime? lastUpdated,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Inventory(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      cratesIn: cratesIn ?? this.cratesIn,
      cratesOut: cratesOut ?? this.cratesOut,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      uuid: uuid ?? this.uuid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
