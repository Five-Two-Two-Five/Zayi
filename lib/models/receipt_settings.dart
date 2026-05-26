class ReceiptSettings {
  final String businessName;
  final String address;
  final String taxId;
  final String phone;
  final String email;
  final String footerNote;
  final double defaultTaxRate;

  ReceiptSettings({
    required this.businessName,
    required this.address,
    required this.taxId,
    required this.phone,
    required this.email,
    required this.footerNote,
    required this.defaultTaxRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'business_name': businessName,
      'address': address,
      'tax_id': taxId,
      'phone': phone,
      'email': email,
      'footer_note': footerNote,
      'default_tax_rate': defaultTaxRate,
    };
  }

  factory ReceiptSettings.fromMap(Map<String, dynamic> map) {
    return ReceiptSettings(
      businessName: map['business_name'] ?? 'Zayi Enterprise',
      address: map['address'] ?? '',
      taxId: map['tax_id'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      footerNote: map['footer_note'] ?? 'Thank you for your business!',
      defaultTaxRate: (map['default_tax_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ReceiptSettings copyWith({
    String? businessName,
    String? address,
    String? taxId,
    String? phone,
    String? email,
    String? footerNote,
    double? defaultTaxRate,
  }) {
    return ReceiptSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      footerNote: footerNote ?? this.footerNote,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
    );
  }
}
