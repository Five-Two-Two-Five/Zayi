import 'package:flutter/material.dart';
import 'receipt_settings_screen.dart';
import 'payment_charges_screen.dart';
import 'printer_settings_screen.dart';
import 'whatsapp_settings_screen.dart'; // Import WhatsAppSettingsScreen
import '../theme/insta_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          // ... existing ListTiles ...
          ListTile(
            leading: const Icon(Icons.chat, color: InstaPalette.accent),
            title: const Text('WhatsApp Bot Setup'),
            subtitle: const Text('Configure your WhatsApp Business API credentials'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsAppSettingsScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: InstaPalette.accent),
            title: const Text('Receipt Settings'),
            subtitle: const Text('Configure business name, address, and tax info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SettingsDetailScreen(title: 'Receipt Settings', child: ReceiptSettingsForm()))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payment, color: InstaPalette.accent),
            title: const Text('Payment Method Charges'),
            subtitle: const Text('Configure transaction fees for payment methods'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SettingsDetailScreen(title: 'Payment Charges', child: PaymentChargesForm()))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.print, color: InstaPalette.accent),
            title: const Text('Printer Settings'),
            subtitle: const Text('Connect and manage thermal receipt printers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SettingsDetailScreen(title: 'Printer Settings', child: PrinterSettingsScreen()))),
          ),
        ],
      ),
    );
  }
}

class _SettingsDetailScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsDetailScreen({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: child,
    );
  }
}
