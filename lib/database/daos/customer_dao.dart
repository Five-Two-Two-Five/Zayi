import 'package:sqflite/sqflite.dart';
import '../../models/customer.dart';
import '../database_helper.dart';

class CustomerDao {
  final Database db;

  CustomerDao(this.db);

  Future<int> create(Customer customer) async {
    final syncData = DatabaseHelper.generateSyncData();
    final updatedCustomer = customer.copyWith(
      uuid: syncData['uuid'],
      lastUpdated: DateTime.parse(syncData['last_updated']),
      isSynced: false,
      isDeleted: false,
    );
    return await db.insert('customers', updatedCustomer.toMap());
  }

  Future<List<Customer>> getAll() async {
    final result = await db.query(
      'customers',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> update(Customer customer) async {
    final updatedCustomer = customer.copyWith(
      lastUpdated: DateTime.now(),
      isSynced: false,
    );
    return await db.update(
      'customers',
      updatedCustomer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.update(
      'customers',
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
