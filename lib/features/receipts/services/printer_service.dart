// lib/features/receipts/services/printer_service.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../data/models/receipt_template.dart';

class PrinterService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  Future<void> printReceipt(ReceiptTemplate template, List<Map<String, dynamic>> items) async {
    bool? isConnected = await printer.isConnected;
    if (isConnected != true) return;

    printer.printCustom(template.headerSettings['businessName'] ?? '', 3, 1);
    printer.printNewLine();
    
    for (var item in items) {
      printer.printCustom("${item['name']} x${item['qty']}", 1, 0);
    }
    
    printer.printNewLine();
    printer.printCustom(template.footerSettings['message'] ?? '', 1, 1);
    printer.paperCut();
  }
}
