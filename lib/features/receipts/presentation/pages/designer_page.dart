// lib/features/receipts/presentation/pages/designer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/receipt_renderer.dart';
import '../providers/designer_provider.dart';
import '../../../../providers/providers.dart';

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
      appBar: AppBar(title: Text(widget.isReadOnly ? "View Receipt" : "Receipt Designer")),
      body: Column(
        children: [
          // Top Panel: Style Settings (Only show if NOT in read-only mode)
          if (!widget.isReadOnly)
            SizedBox(
              height: 220, 
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("LAYOUT & LOGO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        ref.read(designerProvider.notifier).updateHeader({'logo': bytes});
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text("Select Logo"),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Show Header"),
                    trailing: Switch(
                      value: template.headerSettings['show'] ?? true,
                      onChanged: (v) => ref.read(designerProvider.notifier).updateHeader({'show': v}),
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Read-only mode: Business details are locked to the settings configuration.",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          // Bottom Panel: Live Preview
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: settingsAsync.when(
                    data: (settings) => PdfPreview(
                      build: (format) async {
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
                        
                        // Apply Global Settings
                        dataToRender['issuer'] = settings.businessName;
                        dataToRender['address'] = settings.address;
                        dataToRender['taxId'] = settings.taxId;
                        dataToRender['phone'] = settings.phone;
                        dataToRender['footer'] = settings.footerNote;

                        final doc = await ReceiptRenderer.render(
                          template, 
                          dataToRender, 
                          isDigital: _isDigitalFormat,
                        );
                        return doc.save();
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error loading settings: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
