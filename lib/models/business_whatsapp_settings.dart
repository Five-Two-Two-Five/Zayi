class BusinessWhatsappSettings {
  final int? id;
  final String businessName;
  final String phoneNumberId;
  final String accessToken;
  final String verifyToken;
  final DateTime createdAt;
  final bool useUnofficialWebhook;

  BusinessWhatsappSettings({
    this.id,
    required this.businessName,
    required this.phoneNumberId,
    required this.accessToken,
    required this.verifyToken,
    required this.createdAt,
    this.useUnofficialWebhook = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_name': businessName,
      'phone_number_id': phoneNumberId,
      'access_token': accessToken,
      'verify_token': verifyToken,
      'created_at': createdAt.toIso8601String(),
      'use_unofficial_webhook': useUnofficialWebhook ? 1 : 0,
    };
  }

  factory BusinessWhatsappSettings.fromMap(Map<String, dynamic> map) {
    return BusinessWhatsappSettings(
      id: map['id'],
      businessName: map['business_name'],
      phoneNumberId: map['phone_number_id'],
      accessToken: map['access_token'],
      verifyToken: map['verify_token'],
      createdAt: DateTime.parse(map['created_at']),
      useUnofficialWebhook: (map['use_unofficial_webhook'] ?? 0) == 1,
    );
  }
}
