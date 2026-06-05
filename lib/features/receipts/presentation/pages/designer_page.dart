import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../data/models/receipt_template.dart';
import '../../services/receipt_renderer.dart';
import '../providers/designer_provider.dart';
import '../../../../providers/providers.dart';
import '../../../../models/receipt_settings.dart';
import '../../../../theme/insta_theme.dart';

class DesignerPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? transactionData;
  final bool isReadOnly;

  const DesignerPage({super.key, this.transactionData, this.isReadOnly = false});

  @override
  ConsumerState<DesignerPage> createState() => _DesignerPageState();
}

class _DesignerPageState extends ConsumerState<DesignerPage> {
  bool _isDigitalFormat = false;

  @override
  Widget build(BuildContext context) {
    final template = ref.watch(designerProvider);
    final settingsAsync = ref.watch(receiptSettingsProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "View Receipt" : "View Receipt"),
      ),
      body: Column(
        children: [
          // Top Panel: Style Settings
          if (!widget.isReadOnly)
            SizedBox(
              height: 160,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("LAYOUT OPTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Format: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text("Thermal"),
                        selected: !_isDigitalFormat,
                        onSelected: (v) => setState(() => _isDigitalFormat = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("E-Receipt"),
                        selected: _isDigitalFormat,
                        onSelected: (v) => setState(() => _isDigitalFormat = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Show Header"),
                    subtitle: const Text("Toggle business identity display", style: TextStyle(fontSize: 11)),
                    trailing: Switch(
                      value: template.headerSettings['show'] ?? true,
                      onChanged: (v) => ref.read(designerProvider.notifier).updateHeader({'show': v}),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Panel: Live Preview
          Expanded(
            child: settingsAsync.when(
              data: (settings) => PdfPreview(
                build: (format) => _generatePdf(template, settings),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading settings: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdf(ReceiptTemplate template, ReceiptSettings settings) async {
    final dataToRender = Map<String, dynamic>.from(widget.transactionData ?? {
      'receiptNumber': '1-SAMPLE',
      'customerName': 'Sample Customer',
      'date': '2026-05-26 12:00 PM',
      'items': [{'name': 'Product Name', 'qty': 1, 'total': '100.00'}],
      'subTotal': '100.00',
      'total': '100.00',
      'cash': '100.00',
      'balance': '0.00',
    });

    dataToRender['issuer'] = settings.businessName;
    dataToRender['address'] = settings.address;
    dataToRender['taxId'] = settings.taxId;
    dataToRender['phone'] = settings.phone;
    dataToRender['email'] = settings.email;
    dataToRender['footer'] = settings.footerNote;

    if (settings.logoPath != null) {
      final file = File(settings.logoPath!);
      if (await file.exists()) {
        dataToRender['logoBytes'] = await file.readAsBytes();
      }
    }

    final doc = await ReceiptRenderer.render(
      template,
      dataToRender,
      isDigital: _isDigitalFormat,
    );
    return doc.save();
  }
}
