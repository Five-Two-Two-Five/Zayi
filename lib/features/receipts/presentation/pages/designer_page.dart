// lib/features/receipts/presentation/pages/designer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/receipt_renderer.dart';
import '../providers/designer_provider.dart';

class DesignerPage extends ConsumerWidget {
  final Map<String, dynamic>? transactionData;
  final bool isReadOnly;

  const DesignerPage({super.key, this.transactionData, this.isReadOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = ref.watch(designerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isReadOnly ? "View Receipt" : "Receipt Designer")),
      body: Column(
        children: [
          // Top Panel: Settings (Only show if NOT in read-only mode)
          if (!isReadOnly)
            SizedBox(
              height: 250, 
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "Business Name"),
                    onChanged: (v) => ref.read(designerProvider.notifier).updateHeader({'businessName': v}),
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
                    title: const Text("Show Header"),
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
            child: Column(
              children: [
                Expanded(
                  child: PdfPreview(
                    build: (format) async {
                      final dataToRender = Map<String, dynamic>.from(transactionData ?? {
                        'receiptNumber': '1-2112076',
                        'customerName': 'Nikil arora',
                        'date': '2026-05-25 07:50:27pm',
                        'items': [{'name': 'Apple juice 750 ml', 'qty': 1, 'total': '250,00'}],
                        'subTotal': '250,00',
                        'total': '250,00',
                        'cash': '250,00',
                        'balance': '0.00'
                      });
                      
                      if (template.headerSettings['businessName'] != null) {
                        dataToRender['issuer'] = template.headerSettings['businessName'];
                      }

                      final doc = await ReceiptRenderer.render(template, dataToRender);
                      return doc.save();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text("Print"),
                        onPressed: () {
                           // Printing is handled by PdfPreview
                        },
                      ),
                      // We can add a custom share button here for WhatsApp, 
                      // using Printing.sharePdf()
                    ],
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
