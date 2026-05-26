// lib/features/receipts/services/receipt_renderer.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/receipt_template.dart';

/// The engine responsible for rendering receipt layouts.
class ReceiptRenderer {
  static Future<pw.Document> render(
    ReceiptTemplate template, 
    Map<String, dynamic> transactionData, 
    {bool isDigital = false}
  ) async {
    final pdf = pw.Document();
    final format = isDigital ? PdfPageFormat.a5 : PdfPageFormat.roll80;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: isDigital ? const pw.EdgeInsets.all(32) : const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          final items = transactionData['items'] as List<dynamic>? ?? [];
          
          if (isDigital) {
            return _buildDigitalLayout(template, transactionData, items);
          }
          return _buildThermalLayout(template, transactionData, items);
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildDigitalLayout(ReceiptTemplate template, Map<String, dynamic> transactionData, List<dynamic> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Modern Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(transactionData['issuer'] ?? 'Business Name', 
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                if (transactionData['address'] != null) pw.Text(transactionData['address'], style: const pw.TextStyle(fontSize: 10)),
                if (transactionData['phone'] != null) pw.Text('Tel: ${transactionData['phone']}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            if (template.headerSettings['logo'] != null)
              pw.Image(pw.MemoryImage(template.headerSettings['logo']), height: 60),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.orange900, thickness: 2),
        pw.SizedBox(height: 10),
        
        // Transaction Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text(transactionData['customerName'] ?? 'Customer', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('RECEIPT #', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text(transactionData['receiptNumber'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('DATE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text(transactionData['date'] ?? '', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Items Table
        pw.Table(
          border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey300)),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
              ],
            ),
            ...items.map((item) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['name'])),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item['qty']}', textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item['total']}', textAlign: pw.TextAlign.right)),
              ],
            )),
          ],
        ),
        pw.SizedBox(height: 20),

        // Totals Summary
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 150,
              child: pw.Column(
                children: [
                  _buildDigitalTotalRow('Sub Total', transactionData['subTotal']),
                  if (transactionData['tax'] != null) _buildDigitalTotalRow('Tax', transactionData['tax']),
                  pw.Divider(),
                  _buildDigitalTotalRow('Grand Total', transactionData['total'], isBold: true),
                  _buildDigitalTotalRow('Paid', transactionData['cash']),
                  _buildDigitalTotalRow('Balance', transactionData['balance'], color: PdfColors.red700),
                ],
              ),
            ),
          ],
        ),
        
        pw.Spacer(),
        pw.Center(
          child: pw.Text(transactionData['footer'] ?? 'Thank you for choosing us!', 
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
        ),
      ],
    );
  }

  static pw.Widget _buildDigitalTotalRow(String label, String? value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value ?? '0.00', style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalLayout(ReceiptTemplate template, Map<String, dynamic> transactionData, List<dynamic> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header (Business Identity)
        if (template.headerSettings['show'] ?? true)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (template.headerSettings['logo'] != null)
                pw.Image(pw.MemoryImage(template.headerSettings['logo']), height: 50),
              pw.Text(transactionData['issuer'] ?? template.headerSettings['businessName'] ?? 'Business Name', 
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (transactionData['address'] != null && transactionData['address'].toString().isNotEmpty)
                pw.Text(transactionData['address'], style: const pw.TextStyle(fontSize: 10)),
              if (transactionData['taxId'] != null && transactionData['taxId'].toString().isNotEmpty)
                pw.Text('Tax ID: ${transactionData['taxId']}', style: const pw.TextStyle(fontSize: 10)),
              if (transactionData['phone'] != null && transactionData['phone'].toString().isNotEmpty)
                pw.Text('Phone: ${transactionData['phone']}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 5),
            ],
          ),
        
        // Receipt Metadata
        pw.Text('Receipt #: ${transactionData['receiptNumber'] ?? ''}'),
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
        if (transactionData['tax'] != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax:'),
              pw.Text('${transactionData['tax']}'),
            ]
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Sub total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('${transactionData['subTotal']}'),
          ]
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Grand total:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('${transactionData['total']}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ]
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Cash Paid:'),
            pw.Text('${transactionData['cash']}'),
          ]
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Balance Due:'),
            pw.Text('${transactionData['balance']}'),
          ]
        ),
        pw.Divider(),
        
        // Footer
        if (template.footerSettings['show'] ?? true)
          pw.Center(child: pw.Text(transactionData['footer'] ?? template.footerSettings['message'] ?? 'Thank you!', textAlign: pw.TextAlign.center)),
      ],
    );
  }
}
