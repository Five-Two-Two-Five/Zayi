import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class CloudSyncService {
  static final _supabase = Supabase.instance.client;

  /// Syncs inventory balance for a specific product
  static Future<void> syncInventory(String phone, String productName, int balance) async {
    if (phone.isEmpty) return;
    try {
      await _supabase.from('inventory_sync').upsert({
        'phone_number_id': phone,
        'product_name': productName,
        'balance': balance,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'phone_number_id, product_name');
    } catch (e) {
      debugPrint('Supabase Sync Error (Inventory): $e');
    }
  }

  /// Syncs a high-level summary of the business data
  static Future<void> syncSummary({
    required String phone,
    required double revenue,
    required double profit,
    required double debt,
    required double inventoryValue,
  }) async {
    if (phone.isEmpty) return;
    try {
      await _supabase.from('user_summaries').upsert({
        'phone_number_id': phone,
        'total_revenue': revenue,
        'total_profit': profit,
        'total_debt': debt,
        'inventory_value': inventoryValue,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'phone_number_id');
    } catch (e) {
      debugPrint('Supabase Sync Error (Summary): $e');
    }
  }

  /// Logs a recent transaction for quick view in the bot
  static Future<void> syncRecentTransaction({
    required String phone,
    required String type,
    required double amount,
    required String description,
  }) async {
    if (phone.isEmpty) return;
    try {
      await _supabase.from('recent_transactions').insert({
        'phone_number_id': phone,
        'type': type,
        'amount': amount,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase Sync Error (Transaction): $e');
    }
  }

  /// Helper to trigger a full sync of all relevant data
  static Future<void> triggerAllSyncs(BuildContext context, WidgetRef ref) async {
    try {
      final settings = await ref.read(receiptSettingsProvider.future);
      final phone = settings.phone;
      if (phone.isEmpty) return;

      // 1. Sync Summary (All time)
      final summary = await DatabaseHelper.instance.getSummaryInRange(null, null);
      await syncSummary(
        phone: phone,
        revenue: summary['revenue'] ?? 0.0,
        profit: summary['net_profit'] ?? 0.0,
        debt: summary['total_debt'] ?? 0.0,
        inventoryValue: summary['inventory_value'] ?? 0.0,
      );

      // 2. Sync Inventory for each product
      final products = await ref.read(productsProvider.future);
      for (var product in products) {
        final balance = await DatabaseHelper.instance.getInventoryBalance(productId: product.id);
        await syncInventory(phone, product.name, balance);
      }
    } catch (e) {
      debugPrint('Error triggering all syncs: $e');
    }
  }
}

/*
-- SUPABASE SCHEMA --

CREATE TABLE user_summaries (
  phone_number_id TEXT PRIMARY KEY,
  total_revenue DECIMAL(15, 2) DEFAULT 0,
  total_profit DECIMAL(15, 2) DEFAULT 0,
  total_debt DECIMAL(15, 2) DEFAULT 0,
  inventory_value DECIMAL(15, 2) DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE inventory_sync (
  phone_number_id TEXT,
  product_name TEXT,
  balance INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (phone_number_id, product_name)
);

CREATE TABLE recent_transactions (
  id BIGSERIAL PRIMARY KEY,
  phone_number_id TEXT,
  type TEXT,
  amount DECIMAL(15, 2),
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
*/
