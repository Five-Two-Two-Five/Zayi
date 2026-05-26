// lib/features/receipts/services/printer_service.dart
import '../data/models/receipt_template.dart';

class PrinterService {
  // Printer support currently disabled due to dependency conflicts.
  Future<void> printReceipt(ReceiptTemplate template, List<Map<String, dynamic>> items) async {
    // Implement using available printer package once resolved.
    print("Printer support disabled.");
  }
}
