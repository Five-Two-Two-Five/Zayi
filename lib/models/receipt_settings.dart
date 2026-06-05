import 'dart:convert';
import 'payment_method_charge.dart';

class ReceiptSettings {
  final String businessName;
  final String address;
  final String taxId;
  final String phone;
  final String email;
  final String footerNote;
  final double defaultTaxRate;
  final String? logoPath;
  final String baseCurrency;
  final double defaultExchangeRate;
  final List<Map<String, dynamic>> predefinedTaxes;
  final List<PaymentMethodCharge> paymentMethodCharges;
  final String? rememberedPrinterAddress;

  ReceiptSettings({
    required this.businessName,
    required this.address,
    required this.taxId,
    required this.phone,
    required this.email,
    required this.footerNote,
    required this.defaultTaxRate,
    this.defaultExchangeRate = 1.0,
    this.logoPath,
    this.baseCurrency = 'USD',
    this.predefinedTaxes = const [],
    this.paymentMethodCharges = const [],
    this.rememberedPrinterAddress,
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
      'default_exchange_rate': defaultExchangeRate,
      'logo_path': logoPath,
      'base_currency': baseCurrency,
      'predefined_taxes': jsonEncode(predefinedTaxes),
      'payment_method_charges': jsonEncode(paymentMethodCharges.map((c) => c.toMap()).toList()),
      'remembered_printer_address': rememberedPrinterAddress,
    };
  }

  factory ReceiptSettings.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> taxes = [];
    if (map['predefined_taxes'] != null) {
      try {
        final decoded = map['predefined_taxes'] is String 
            ? jsonDecode(map['predefined_taxes']) 
            : map['predefined_taxes'];
        if (decoded is List) {
           taxes = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (e) {
        // debugPrint('Error decoding predefined_taxes: $e');
      }
    }

    List<PaymentMethodCharge> charges = [];
    if (map['payment_method_charges'] != null) {
      try {
        final decoded = map['payment_method_charges'] is String 
            ? jsonDecode(map['payment_method_charges']) 
            : map['payment_method_charges'];
        if (decoded is List) {
          charges = decoded.map((c) => PaymentMethodCharge.fromMap(c)).toList();
        }
      } catch (e) {
        // debugPrint('Error decoding payment_method_charges: $e');
      }
    }

    return ReceiptSettings(
      businessName: map['business_name'] ?? 'Zayi Enterprise',
      address: map['address'] ?? '',
      taxId: map['tax_id'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      footerNote: map['footer_note'] ?? 'Thank you for your business!',
      defaultTaxRate: (map['default_tax_rate'] as num?)?.toDouble() ?? 0.0,
      defaultExchangeRate: (map['default_exchange_rate'] as num?)?.toDouble() ?? 1.0,
      logoPath: map['logo_path'],
      baseCurrency: map['base_currency'] ?? 'USD',
      predefinedTaxes: taxes,
      paymentMethodCharges: charges,
      rememberedPrinterAddress: map['remembered_printer_address'],
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
    double? defaultExchangeRate,
    String? logoPath,
    String? baseCurrency,
    List<Map<String, dynamic>>? predefinedTaxes,
    List<PaymentMethodCharge>? paymentMethodCharges,
    String? rememberedPrinterAddress,
  }) {
    return ReceiptSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      footerNote: footerNote ?? this.footerNote,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultExchangeRate: defaultExchangeRate ?? this.defaultExchangeRate,
      logoPath: logoPath ?? this.logoPath,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      predefinedTaxes: predefinedTaxes ?? this.predefinedTaxes,
      paymentMethodCharges: paymentMethodCharges ?? this.paymentMethodCharges,
      rememberedPrinterAddress: rememberedPrinterAddress ?? this.rememberedPrinterAddress,
    );
  }
}
