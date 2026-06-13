import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? get _userId => _auth.currentUser?.uid;

  // Sync all tables
  Future<void> syncAll() async {
    if (_userId == null) return;
    if (_isSyncing) return;

    _isSyncing = true;
    debugPrint('SyncService: Starting sync...');

    try {
      final tables = [
        'products',
        'suppliers',
        'customers',
        'purchases',
        'sales',
        'expenses',
        'inventory',
        'fixed_assets',
        'equity_ledger',
        'receipt_settings',
        'sale_payments',
      ];

      for (var table in tables) {
        await _syncTable(table);
      }
      debugPrint('SyncService: Sync completed successfully.');
    } catch (e) {
      debugPrint('SyncService: Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTable(String tableName) async {
    if (_userId == null) return;

    final db = await _dbHelper.database;
    
    // 1. Push local changes to Firestore
    final localChanges = await db.query(tableName, where: 'is_synced = 0');
    for (var row in localChanges) {
      final uuid = row['uuid'] as String?;
      if (uuid == null) continue;

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection(tableName)
          .doc(uuid)
          .set(Map<String, dynamic>.from(row)..remove('id')..remove('is_synced'));

      await db.update(
        tableName,
        {'is_synced': 1},
        where: 'uuid = ?',
        whereArgs: [uuid],
      );
    }

    // 2. Pull remote changes from Firestore
    // For simplicity, we fetch everything modified after a certain time 
    // or just fetch all for now and compare last_updated.
    // In a production app, we'd store the last_sync_timestamp locally.
    
    final querySnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection(tableName)
        .get();

    for (var doc in querySnapshot.docs) {
      final remoteData = doc.data();
      final uuid = doc.id;
      
      final localResult = await db.query(tableName, where: 'uuid = ?', whereArgs: [uuid]);
      
      if (localResult.isEmpty) {
        // Insert new record from remote
        await db.insert(tableName, Map<String, dynamic>.from(remoteData)..['is_synced'] = 1);
      } else {
        final localRow = localResult.first;
        final localLastUpdated = DateTime.parse(localRow['last_updated'] as String);
        final remoteLastUpdated = DateTime.parse(remoteData['last_updated'] as String);

        if (remoteLastUpdated.isAfter(localLastUpdated)) {
          // Update local record if remote is newer
          await db.update(
            tableName,
            Map<String, dynamic>.from(remoteData)..['is_synced'] = 1,
            where: 'uuid = ?',
            whereArgs: [uuid],
          );
        }
      }
    }
    
    // 3. Clean up soft-deleted records that are synced
    await db.delete(tableName, where: 'is_deleted = 1 AND is_synced = 1');
  }
}
