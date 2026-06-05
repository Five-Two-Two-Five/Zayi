class Inventory {
  final int? id;
  final int productId;
  final int cratesIn;
  final int cratesOut;
  final int balance;
  final DateTime createdAt;

  Inventory({
    this.id,
    this.productId = 1,
    required this.cratesIn,
    required this.cratesOut,
    required this.balance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'trays_in': cratesIn,
      'trays_out': cratesOut,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
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
    );
  }
}
