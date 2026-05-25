// lib/features/receipts/services/receipt_renderer.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/receipt_template.dart';

/// The engine responsible for rendering receipt layouts.
class ReceiptRenderer {
  static Future<pw.Document> render(ReceiptTemplate template, Map<String, dynamic> transactionData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              children: [
                // Header
                if (template.headerSettings['show'] ?? true)
                  pw.Column(children: [
                    pw.Text(template.headerSettings['businessName'] ?? 'Business Name', 
                            style: pw.TextStyle(fontSize: 16)),
                    pw.Text(template.headerSettings['address'] ?? ''),
                  ]),
                pw.Divider(),
                // Body
                pw.Text('Items placeholder'),
                pw.Divider(),
                // Footer
                if (template.footerSettings['show'] ?? true)
                  pw.Text(template.footerSettings['message'] ?? 'Thank you!'),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }
}
