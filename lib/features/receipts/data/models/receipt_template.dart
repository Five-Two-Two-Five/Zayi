// lib/features/receipts/data/models/receipt_template.dart
import 'package:hive/hive.dart';

part 'receipt_template.g.dart';

@HiveType(typeId: 0)
class ReceiptTemplate extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final Map<String, dynamic> headerSettings;
  @HiveField(3)
  final Map<String, dynamic> footerSettings;
  @HiveField(4)
  final Map<String, dynamic> styling;

  ReceiptTemplate({
    required this.id,
    required this.name,
    this.headerSettings = const {},
    this.footerSettings = const {},
    this.styling = const {},
  });
}
