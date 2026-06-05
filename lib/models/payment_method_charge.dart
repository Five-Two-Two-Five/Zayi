class PaymentMethodCharge {
  final String method;
  final String description;
  final bool isPercentage;
  final double value;

  PaymentMethodCharge({
    required this.method,
    required this.description,
    required this.isPercentage,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'description': description,
      'isPercentage': isPercentage,
      'value': value,
    };
  }

  factory PaymentMethodCharge.fromMap(Map<String, dynamic> map) {
    return PaymentMethodCharge(
      method: map['method'] ?? '',
      description: map['description'] ?? '',
      isPercentage: map['isPercentage'] == 1 || map['isPercentage'] == true,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  PaymentMethodCharge copyWith({
    String? method,
    String? description,
    bool? isPercentage,
    double? value,
  }) {
    return PaymentMethodCharge(
      method: method ?? this.method,
      description: description ?? this.description,
      isPercentage: isPercentage ?? this.isPercentage,
      value: value ?? this.value,
    );
  }
}
