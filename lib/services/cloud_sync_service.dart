import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class CloudSyncService {
  static final _supabase = Supabase.instance.client;

  static Future<void> syncInventory(String phoneNumberId, String productName, int balance) async {
    try {
      await _supabase.from('inventory_sync').upsert({
        'phone_number_id': phoneNumberId,
        'product_name': productName,
        'balance': balance,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'phone_number_id, product_name');
    } catch (e) {
      debugPrint('Supabase Sync Error: $e');
    }
  }
}
