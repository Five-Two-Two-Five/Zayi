// lib/features/receipts/services/whatsapp_service.dart
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Simple WhatsApp text share
  static Future<void> sendMessage(String phone, String message) async {
    final Uri url = Uri.parse(
        "https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Share a file (PDF) to WhatsApp
  static Future<void> shareReceiptFile(String filePath) async {
    final file = XFile(filePath);
    await Share.instance.shareXFiles([file], text: 'Here is your receipt.');
  }
}
