class Inventory {
  final int? id;
  final int traysIn;
  final int traysOut;
  final int balance;
  final DateTime createdAt;

  Inventory({
    this.id,
    required this.traysIn,
    required this.traysOut,
    required this.balance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trays_in': traysIn,
      'trays_out': traysOut,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      id: map['id'],
      traysIn: map['trays_in'],
      traysOut: map['trays_out'],
      balance: map['balance'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
