import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class IntentPrinterService {
  static const platform = MethodChannel('com.eggtrader.printer/print');

  static Future<bool> printViaIntent(String data) async {
    try {
      final bool result = await platform.invokeMethod('print', {'content': data});
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to print via intent: '${e.message}'.");
      return false;
    }
  }
}
