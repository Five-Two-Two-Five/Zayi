// lib/features/receipts/data/repositories/receipt_repository.dart
import 'package:hive/hive.dart';
import '../models/receipt_template.dart';

class ReceiptRepository {
  static const String _boxName = 'receipt_templates';

  Future<void> saveTemplate(ReceiptTemplate template) async {
    final box = await Hive.openBox<ReceiptTemplate>(_boxName);
    await box.put(template.id, template);
  }

  Future<ReceiptTemplate?> getTemplate(String id) async {
    final box = await Hive.openBox<ReceiptTemplate>(_boxName);
    return box.get(id);
  }

  Future<List<ReceiptTemplate>> getAllTemplates() async {
    final box = await Hive.openBox<ReceiptTemplate>(_boxName);
    return box.values.toList();
  }
}
