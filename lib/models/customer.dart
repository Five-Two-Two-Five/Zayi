class Customer {
  final int? id;
  final String name;
  final String phone;
  final String location;
  final String notes;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'location': location,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? location,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
