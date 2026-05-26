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
          final items = transactionData['items'] as List<dynamic>? ?? [];
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              if (template.headerSettings['show'] ?? true)
                pw.Column(children: [
                  if (template.headerSettings['logo'] != null)
                    pw.Image(pw.MemoryImage(template.headerSettings['logo']), height: 50),
                  pw.Text(template.headerSettings['businessName'] ?? 'Business Name', 
                          style: pw.TextStyle(fontSize: 16)),
                  pw.Text(template.headerSettings['address'] ?? ''),
                  pw.SizedBox(height: 5),
                ]),
              
              // Receipt Details
              pw.Text('Receipt #: ${transactionData['receiptNumber'] ?? ''}'),
              pw.Text('Issuer: ${transactionData['issuer'] ?? ''}'), // Changed Cashier to Issuer
              pw.Text('Customer: ${transactionData['customerName'] ?? ''}'),
              pw.Text('Date: ${transactionData['date'] ?? ''}'),
              pw.Divider(),

              // Items
              pw.Row(children: [
                pw.Expanded(child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 10),
                pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
              ...items.map((item) => pw.Row(children: [
                pw.Expanded(child: pw.Text(item['name'])),
                pw.Text('${item['qty']}'),
                pw.SizedBox(width: 10),
                pw.Text('${item['total']}'),
              ])),
              pw.Divider(),

              // Totals
              pw.Text('Sub total: ${transactionData['subTotal']}'),
              pw.Text('Grand total: ${transactionData['total']}'),
              pw.Text('Cash: ${transactionData['cash']}'),
              pw.Text('Balance: ${transactionData['balance']}'),
              pw.Divider(),
              
              // Footer
              if (template.footerSettings['show'] ?? true)
                pw.Center(child: pw.Text(template.footerSettings['message'] ?? 'Thank you!')),
            ],
          );
        },
      ),
    );
    return pdf;
  }
}
