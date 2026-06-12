import 'package:sqflite/sqflite.dart';
import '../../models/product.dart';

class ProductDao {
  final Database db;

  ProductDao(this.db);

  Future<int> create(Product product) async {
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAll() async {
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getById(int id) async {
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  Future<int> update(Product product) async {
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
