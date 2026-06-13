import 'package:sqflite/sqflite.dart';
import '../../models/supplier.dart';
import '../database_helper.dart';

class SupplierDao {
  final Database db;

  SupplierDao(this.db);

  Future<int> create(Supplier supplier) async {
    final syncData = DatabaseHelper.generateSyncData();
    final updatedSupplier = supplier.copyWith(
      uuid: syncData['uuid'],
      lastUpdated: DateTime.parse(syncData['last_updated']),
      isSynced: false,
      isDeleted: false,
    );
    return await db.insert('suppliers', updatedSupplier.toMap());
  }

  Future<List<Supplier>> getAll() async {
    final result = await db.query(
      'suppliers',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  Future<int> update(Supplier supplier) async {
    final updatedSupplier = supplier.copyWith(
      lastUpdated: DateTime.now(),
      isSynced: false,
    );
    return await db.update(
      'suppliers',
      updatedSupplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.update(
      'suppliers',
      {
        'is_deleted': 1,
        'last_updated': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
