import 'package:sqflite/sqflite.dart';
import '../../models/customer.dart';

class CustomerDao {
  final Database db;

  CustomerDao(this.db);

  Future<int> create(Customer customer) async {
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAll() async {
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> update(Customer customer) async {
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
