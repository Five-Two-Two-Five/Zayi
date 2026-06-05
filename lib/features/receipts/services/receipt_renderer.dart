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
        margin: isDigital ? const pw.EdgeInsets.all(32) : const pw.EdgeInsets.all(30),
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
    final logoBytes = transactionData['logoBytes'] ?? template.headerSettings['logo'];
    final tax = double.tryParse(transactionData['tax'] ?? '0') ?? 0;
    final subTotal = transactionData['subTotal'];
    final total = transactionData['total'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ... Header ...
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(transactionData['issuer'] ?? 'Business Name', 
                        style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                if (transactionData['address'] != null) pw.Text(transactionData['address'], style: const pw.TextStyle(fontSize: 15)),
                if (transactionData['taxId'] != null && transactionData['taxId'].toString().isNotEmpty) pw.Text('Tax ID: ${transactionData['taxId']}', style: const pw.TextStyle(fontSize: 15)),
                if (transactionData['phone'] != null) pw.Text('Tel: ${transactionData['phone']}', style: const pw.TextStyle(fontSize: 15)),
                if (transactionData['email'] != null && transactionData['email'].toString().isNotEmpty) pw.Text(transactionData['email'], style: const pw.TextStyle(fontSize: 15)),
              ],
            ),
            if (logoBytes != null)
              pw.Image(pw.MemoryImage(logoBytes), height: 66),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.orange900, thickness: 2),
        pw.SizedBox(height: 20),
        
        // ... Transaction Info ...
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text(transactionData['customerName'] ?? 'Customer', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('RECEIPT #', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text(transactionData['receiptNumber'] ?? '', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('DATE', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text(transactionData['date'] ?? '', style: const pw.TextStyle(fontSize: 15)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),

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
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
              ],
            ),
            ...items.map((item) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['name'], style: const pw.TextStyle(fontSize: 15))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item['qty']}', style: const pw.TextStyle(fontSize: 15), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item['total']}', style: const pw.TextStyle(fontSize: 15), textAlign: pw.TextAlign.right)),
              ],
            )),
          ],
        ),
        pw.SizedBox(height: 30),

        // Totals Summary
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 180,
              child: pw.Column(
                children: [
                  if (subTotal != total) _buildDigitalTotalRow('Sub Total', subTotal),
                  if (tax > 0) _buildDigitalTotalRow(transactionData['taxLabel'] ?? 'Tax', transactionData['tax']),
                  pw.Divider(),
                  _buildDigitalTotalRow('Grand Total', total, isBold: true),
                  _buildDigitalTotalRow('Paid', transactionData['cash']),
                  _buildDigitalTotalRow('Balance', transactionData['balance'], color: PdfColors.red700),
                ],
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        pw.Spacer(),
        if (transactionData['phone'] != null && transactionData['phone'].toString().isNotEmpty)
          pw.Center(
            child: pw.BarcodeWidget(
              data: transactionData['phone'].toString(),
              barcode: pw.Barcode.qrCode(),
              width: 70,
              height: 70,
            ),
          ),
        pw.SizedBox(height: 15),
        pw.Center(
          child: pw.Text(transactionData['footer'] ?? 'Thank you for choosing us!', 
                  style: pw.TextStyle(fontSize: 15, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
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
          pw.Text(label, style: pw.TextStyle(fontSize: 15, color: PdfColors.grey700)),
          pw.Text(value ?? '0.00', style: pw.TextStyle(fontSize: 15, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }
  static pw.Widget _buildThermalLayout(ReceiptTemplate template, Map<String, dynamic> transactionData, List<dynamic> items) {
    final logoBytes = transactionData['logoBytes'] ?? template.headerSettings['logo'];
    final tax = double.tryParse(transactionData['tax'] ?? '0') ?? 0;
    final subTotal = transactionData['subTotal'];
    final total = transactionData['total'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header (Business Identity)
        if (template.headerSettings['show'] ?? true)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null)
                pw.Image(pw.MemoryImage(logoBytes), height: 56),
              pw.Text(transactionData['issuer'] ?? template.headerSettings['businessName'] ?? 'Business Name', 
                      style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold)),
              if (transactionData['address'] != null && transactionData['address'].toString().isNotEmpty)
                pw.Text(transactionData['address'], style: const pw.TextStyle(fontSize: 15)),
              if (transactionData['taxId'] != null && transactionData['taxId'].toString().isNotEmpty)
                pw.Text('Tax ID: ${transactionData['taxId']}', style: const pw.TextStyle(fontSize: 15)),
              if (transactionData['phone'] != null && transactionData['phone'].toString().isNotEmpty)
                pw.Text('Phone: ${transactionData['phone']}', style: const pw.TextStyle(fontSize: 15)),
              if (transactionData['email'] != null && transactionData['email'].toString().isNotEmpty)
                pw.Text('Email: ${transactionData['email']}', style: const pw.TextStyle(fontSize: 15)),
              pw.SizedBox(height: 15),
            ],
          ),
        
        // Receipt Metadata
        pw.Text('Receipt #: ${transactionData['receiptNumber'] ?? ''}', style: const pw.TextStyle(fontSize: 15)),
        pw.Text('Customer: ${transactionData['customerName'] ?? ''}', style: const pw.TextStyle(fontSize: 15)),
        pw.Text('Date: ${transactionData['date'] ?? ''}', style: const pw.TextStyle(fontSize: 15)),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 20),

        // Items
        pw.Row(children: [
          pw.Expanded(child: pw.Text('Product', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold))),
          pw.Text('Qty', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 15),
          pw.Text('Total', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        ]),
        ...items.map((item) => pw.Row(children: [
          pw.Expanded(child: pw.Text(item['name'], style: const pw.TextStyle(fontSize: 15))),
          pw.Text('${item['qty']}', style: const pw.TextStyle(fontSize: 15)),
          pw.SizedBox(width: 15),
          pw.Text('${item['total']}', style: const pw.TextStyle(fontSize: 15)),
        ])),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 20),

        // Totals
        if (tax > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${transactionData['taxLabel'] ?? 'Tax'}:', style: const pw.TextStyle(fontSize: 15)),
              pw.Text('${transactionData['tax']}', style: const pw.TextStyle(fontSize: 15)),
            ]
          ),
        if (subTotal != total)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Sub total:', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.Text('${transactionData['subTotal']}', style: const pw.TextStyle(fontSize: 15)),
            ]
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Grand total:', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text('${transactionData['total']}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ]
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Cash Paid:', style: const pw.TextStyle(fontSize: 15)),
            pw.Text('${transactionData['cash']}', style: const pw.TextStyle(fontSize: 15)),
          ]
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Balance Due:', style: const pw.TextStyle(fontSize: 15)),
            pw.Text('${transactionData['balance']}', style: const pw.TextStyle(fontSize: 15)),
          ]
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 20),
        
        // Footer
        if (template.footerSettings['show'] ?? true)
          pw.Center(
            child: pw.Column(
              children: [
                if (transactionData['phone'] != null && transactionData['phone'].toString().isNotEmpty)
                  pw.BarcodeWidget(
                    data: transactionData['phone'].toString(),
                    barcode: pw.Barcode.qrCode(),
                    width: 70,
                    height: 70,
                  ),
                pw.SizedBox(height: 15),
                pw.Text(transactionData['footer'] ?? template.footerSettings['message'] ?? 'Thank you!', style: const pw.TextStyle(fontSize: 15), textAlign: pw.TextAlign.center),
              ],
            ),
          ),      ],
    );
  }
}
