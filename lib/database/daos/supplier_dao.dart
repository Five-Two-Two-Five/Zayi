import 'package:sqflite/sqflite.dart';
import '../../models/supplier.dart';

class SupplierDao {
  final Database db;

  SupplierDao(this.db);

  Future<int> create(Supplier supplier) async {
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<List<Supplier>> getAll() async {
    final result = await db.query('suppliers', orderBy: 'name ASC');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  Future<int> update(Supplier supplier) async {
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }
}
