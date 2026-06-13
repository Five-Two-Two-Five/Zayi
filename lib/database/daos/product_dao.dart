import 'package:sqflite/sqflite.dart';
import '../../models/product.dart';
import '../database_helper.dart';

class ProductDao {
  final Database db;

  ProductDao(this.db);

  Future<int> create(Product product) async {
    final syncData = DatabaseHelper.generateSyncData();
    final updatedProduct = product.copyWith(
      uuid: syncData['uuid'],
      lastUpdated: DateTime.parse(syncData['last_updated']),
      isSynced: false,
      isDeleted: false,
    );
    return await db.insert('products', updatedProduct.toMap());
  }

  Future<List<Product>> getAll() async {
    final result = await db.query(
      'products',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getById(int id) async {
    final result = await db.query(
      'products',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  Future<int> update(Product product) async {
    final updatedProduct = product.copyWith(
      lastUpdated: DateTime.now(),
      isSynced: false,
    );
    return await db.update(
      'products',
      updatedProduct.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.update(
      'products',
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
