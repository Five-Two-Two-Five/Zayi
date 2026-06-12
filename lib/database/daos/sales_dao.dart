import 'package:sqflite/sqflite.dart';
import '../../models/sale.dart';
import '../../models/purchase.dart';
import 'product_dao.dart';

class SalesDao {
  final Database db;
  final ProductDao productDao;

  SalesDao(this.db) : productDao = ProductDao(db);

  Future<List<Sale>> getSales({
    int limit = 20,
    int offset = 0,
    int? productId,
  }) async {
    final result = await db.query(
      'sales',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  Future<int> create(Sale sale) async {
    final product = await productDao.getById(sale.productId);
    final ratio = product?.subUnitsPerUnit ?? 30;

    return await db.transaction((txn) async {
      // 1. Check inventory balance (in primary units)
      final lastInventory = await txn.query(
        'inventory',
        where: 'product_id = ?',
        whereArgs: [sale.productId],
        orderBy: 'id DESC',
        limit: 1,
      );
      final currentUnitBalance = lastInventory.isNotEmpty
          ? lastInventory.first['balance'] as int
          : 0;

      if (currentUnitBalance < sale.cratesSold) {
        throw Exception('Insufficient inventory');
      }

      // 2. FIFO Logic to calculate True COGS and update remaining sub-units
      int subUnitsToConsume = (sale.cratesSold * ratio) + sale.eggsSold;
      double totalCOGS = 0.0;

      // Get all purchases for THIS product with remaining stock, oldest first
      final activePurchases = await txn.query(
        'purchases',
        where: 'product_id = ? AND remaining_eggs > 0',
        whereArgs: [sale.productId],
        orderBy: 'created_at ASC',
      );

      for (var row in activePurchases) {
        if (subUnitsToConsume <= 0) break;

        final purchase = Purchase.fromMap(row);
        int available = purchase.remainingEggs;
        int consumed = available < subUnitsToConsume
            ? available
            : subUnitsToConsume;

        totalCOGS += consumed * (purchase.totalCost / (purchase.crates * ratio));
        subUnitsToConsume -= consumed;

        // Update purchase record
        await txn.update(
          'purchases',
          {'remaining_eggs': available - consumed},
          where: 'id = ?',
          whereArgs: [purchase.id],
        );
      }

      // 3. Fallback for edge cases
      if (subUnitsToConsume > 0) {
        final fallbackResult = await txn.query(
          'purchases',
          where: 'product_id = ?',
          whereArgs: [sale.productId],
          orderBy: 'id DESC',
          limit: 1,
        );
        double fallbackPrice = fallbackResult.isNotEmpty
            ? (Purchase.fromMap(fallbackResult.first).totalCost /
                  (Purchase.fromMap(fallbackResult.first).crates * ratio))
            : (sale.sellingPricePerCrate / ratio);
        totalCOGS += subUnitsToConsume * fallbackPrice;
      }

      // 4. Create the sale with the calculated COGS
      final revenue = sale.totalRevenue;
      final finalTotalCost = totalCOGS + sale.deliveryCost + sale.employeeCost;
      final finalProfit = revenue - finalTotalCost;

      final updatedSale = sale.copyWith(
        totalCost: finalTotalCost,
        profit: finalProfit,
      );

      final id = await txn.insert('sales', updatedSale.toMap());

      // 5. Update inventory (unit balance)
      await txn.insert('inventory', {
        'product_id': sale.productId,
        'trays_in': 0,
        'trays_out': sale.cratesSold,
        'balance': currentUnitBalance - sale.cratesSold,
        'created_at': sale.createdAt.toIso8601String(),
      });

      return id;
    });
  }

  Future<Sale?> getById(int id) async {
    final result = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Sale.fromMap(result.first) : null;
  }

  Future<int> update(Sale sale) async {
    return await db.update(
      'sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> delete(int saleId) async {
    return await db.transaction((txn) async {
      final saleResult = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );
      if (saleResult.isEmpty) return 0;
      final crates = saleResult.first['trays_sold'] as int;
      final productId = saleResult.first['product_id'] as int;
      
      final count = await txn.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );
      
      final lastInventory = await txn.query(
        'inventory',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'id DESC',
        limit: 1,
      );
      final currentBalance = lastInventory.isNotEmpty
          ? lastInventory.first['balance'] as int
          : 0;
          
      await txn.insert('inventory', {
        'product_id': productId,
        'trays_in': crates,
        'trays_out': 0,
        'balance': currentBalance + crates,
        'created_at': DateTime.now().toIso8601String(),
      });
      return count;
    });
  }
}
