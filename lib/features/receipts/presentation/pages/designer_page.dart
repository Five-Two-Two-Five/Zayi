// lib/features/receipts/presentation/pages/designer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../services/receipt_renderer.dart';
import '../providers/designer_provider.dart';

class DesignerPage extends ConsumerWidget {
  const DesignerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = ref.watch(designerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Receipt Designer")),
      body: Row(
        children: [
          // Left Panel: Settings
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Business Name"),
                  onChanged: (v) => ref.read(designerProvider.notifier).updateHeader({'businessName': v}),
                ),
                // Add more settings widgets...
              ],
            ),
          ),
          // Right Panel: Live Preview
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: PdfPreview(
                    build: (format) async {
                      final doc = await ReceiptRenderer.render(template, {});
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
                           // Call PrinterService().printReceipt(...)
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text("WhatsApp"),
                        onPressed: () {
                           // Call WhatsAppService().shareReceiptFile(...)
                        },
                      ),
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
