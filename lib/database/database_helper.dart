import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/inventory.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('egg_trader.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE purchases ADD COLUMN remaining_eggs INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE sales ADD COLUMN eggs_sold INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE suppliers (
        id $idType,
        name $textType,
        phone $textType,
        location $textType,
        notes $textType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textType,
        phone $textType,
        location $textType,
        notes $textType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id $idType,
        supplier_id $intType,
        trays $intType,
        remaining_eggs $intType,
        buying_price_per_tray $realType,
        transport_cost $realType,
        other_cost $realType,
        total_cost $realType,
        notes $textType,
        created_at $textType,
        latitude $realType,
        longitude $realType,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id $idType,
        customer_id $intType,
        trays_sold $intType,
        eggs_sold $intType,
        selling_price_per_tray $realType,
        delivery_cost $realType,
        employee_cost $realType,
        total_revenue $realType,
        total_cost $realType,
        profit $realType,
        amount_paid $realType,
        balance_due $realType,
        notes $textType,
        created_at $textType,
        latitude $realType,
        longitude $realType,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        expense_type $textType,
        amount $realType,
        description $textType,
        created_at $textType,
        latitude $realType,
        longitude $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory (
        id $idType,
        trays_in $intType,
        trays_out $intType,
        balance $intType,
        created_at $textType
      )
    ''');
    
    // Initial inventory balance
    await db.execute('CREATE INDEX idx_inventory_id ON inventory(id)');
    await db.execute('CREATE INDEX idx_purchases_created_at ON purchases(created_at)');
    await db.execute('CREATE INDEX idx_sales_created_at ON sales(created_at)');
    await db.execute('CREATE INDEX idx_expenses_created_at ON expenses(created_at)');
  }

  // --- CRUD Operations ---

  // Suppliers
  Future<int> createSupplier(Supplier supplier) async {
    final db = await instance.database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await instance.database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }
  
  Future<int> updateSupplier(Supplier supplier) async {
    final db = await instance.database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  // Customers
  Future<int> createCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }
  
  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // Purchases
  Future<int> createPurchase(Purchase purchase) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Initialize remaining_eggs for FIFO tracking
      final updatedPurchase = purchase.copyWith(remainingEggs: purchase.crates * 30);
      final id = await txn.insert('purchases', updatedPurchase.toMap());
      
      // Update inventory
      final lastInventory = await txn.query('inventory', orderBy: 'id DESC', limit: 1);
      final currentBalance = lastInventory.isNotEmpty ? lastInventory.first['balance'] as int : 0;
      
      await txn.insert('inventory', {
        'trays_in': purchase.crates,
        'trays_out': 0,
        'balance': currentBalance + purchase.crates,
        'created_at': purchase.createdAt.toIso8601String(),
      });
      
      return id;
    });
  }

  Future<List<Purchase>> getAllPurchases() async {
    final db = await instance.database;
    final result = await db.query('purchases', orderBy: 'created_at DESC');
    return result.map((json) => Purchase.fromMap(json)).toList();
  }

  // Sales
  Future<int> createSale(Sale sale) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // 1. Check inventory balance (in crates)
      final lastInventory = await txn.query('inventory', orderBy: 'id DESC', limit: 1);
      final currentCrateBalance = lastInventory.isNotEmpty ? lastInventory.first['balance'] as int : 0;
      
      if (currentCrateBalance < sale.cratesSold) {
        throw Exception('Insufficient inventory');
      }

      // 2. FIFO Logic to calculate True COGS and update remaining_eggs
      int eggsToConsume = sale.totalEggsSold;
      double totalCOGS = 0.0;

      // Get all purchases with remaining stock, oldest first
      final activePurchases = await txn.query(
        'purchases',
        where: 'remaining_eggs > 0',
        orderBy: 'created_at ASC',
      );

      for (var row in activePurchases) {
        if (eggsToConsume <= 0) break;

        final purchase = Purchase.fromMap(row);
        int available = purchase.remainingEggs;
        int consumed = available < eggsToConsume ? available : eggsToConsume;

        totalCOGS += consumed * purchase.pricePerEgg;
        eggsToConsume -= consumed;

        // Update purchase record
        await txn.update(
          'purchases',
          {'remaining_eggs': available - consumed},
          where: 'id = ?',
          whereArgs: [purchase.id],
        );
      }

      // 3. Fallback for edge cases (should not happen with balance check)
      if (eggsToConsume > 0) {
        final fallbackResult = await txn.query('purchases', orderBy: 'id DESC', limit: 1);
        double fallbackPrice = fallbackResult.isNotEmpty 
            ? Purchase.fromMap(fallbackResult.first).pricePerEgg 
            : (sale.sellingPricePerCrate / 30);
        totalCOGS += eggsToConsume * fallbackPrice;
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
      
      // 5. Update inventory (crate balance)
      await txn.insert('inventory', {
        'trays_in': 0,
        'trays_out': sale.cratesSold,
        'balance': currentCrateBalance - sale.cratesSold,
        'created_at': sale.createdAt.toIso8601String(),
      });
      
      return id;
    });
  }

  Future<List<Sale>> getAllSales() async {
    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'created_at DESC');
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  // Expenses
  Future<int> createExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'created_at DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  // Inventory
  Future<int> getInventoryBalance() async {
    final db = await instance.database;
    final result = await db.query('inventory', orderBy: 'id DESC', limit: 1);
    return result.isNotEmpty ? result.first['balance'] as int : 0;
  }
  
  Future<List<Inventory>> getInventoryHistory() async {
    final db = await instance.database;
    final result = await db.query('inventory', orderBy: 'created_at DESC');
    return result.map((json) => Inventory.fromMap(json)).toList();
  }

  // Metrics
  Future<double> getInventoryValue() async {
    final db = await instance.database;
    final result = await db.query('purchases', where: 'remaining_eggs > 0');
    double totalValue = 0;
    for (var row in result) {
      final p = Purchase.fromMap(row);
      totalValue += p.remainingEggs * p.pricePerEgg;
    }
    return totalValue;
  }

  Future<double> getTotalCustomerDebt() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(balance_due) as total FROM sales');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Reports/Calculations
  Future<Map<String, double>> getTodaySummary() async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final salesResult = await db.rawQuery('SELECT SUM(total_revenue) as revenue, SUM(profit) as profit, SUM(balance_due) as balance FROM sales WHERE created_at LIKE "$today%"');
    final expensesResult = await db.rawQuery('SELECT SUM(amount) as total FROM expenses WHERE created_at LIKE "$today%"');
    
    double revenue = (salesResult.first['revenue'] as num?)?.toDouble() ?? 0.0;
    double profit = (salesResult.first['profit'] as num?)?.toDouble() ?? 0.0;
    double balance = (salesResult.first['balance'] as num?)?.toDouble() ?? 0.0;
    double expenses = (expensesResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Add inventory value and total debt to summary
    final inventoryValue = await getInventoryValue();
    final totalDebt = await getTotalCustomerDebt();

    return {
      'revenue': revenue,
      'profit': profit,
      'balance': balance, // Today's new debt
      'expenses': expenses,
      'inventory_value': inventoryValue,
      'total_debt': totalDebt,
    };
  }

  // --- Delete Operations ---

  Future<int> deleteSupplier(int id) async {
    final db = await instance.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePurchase(int purchaseId) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Get the purchase to know how many crates to remove from inventory
      final purchaseResult = await txn.query('purchases', where: 'id = ?', whereArgs: [purchaseId]);
      if (purchaseResult.isEmpty) return 0;
      
      final crates = purchaseResult.first['trays'] as int;
      
      // Delete the purchase
      final count = await txn.delete('purchases', where: 'id = ?', whereArgs: [purchaseId]);
      
      // Update inventory (Reverse the purchase)
      final lastInventory = await txn.query('inventory', orderBy: 'id DESC', limit: 1);
      final currentBalance = lastInventory.isNotEmpty ? lastInventory.first['balance'] as int : 0;
      
      await txn.insert('inventory', {
        'trays_in': 0,
        'trays_out': crates,
        'balance': currentBalance - crates,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return count;
    });
  }

  Future<int> deleteSale(int saleId) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Get the sale to know how many crates to add back to inventory
      final saleResult = await txn.query('sales', where: 'id = ?', whereArgs: [saleId]);
      if (saleResult.isEmpty) return 0;
      
      final crates = saleResult.first['trays_sold'] as int;
      
      // Delete the sale
      final count = await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);
      
      // Update inventory (Reverse the sale)
      final lastInventory = await txn.query('inventory', orderBy: 'id DESC', limit: 1);
      final currentBalance = lastInventory.isNotEmpty ? lastInventory.first['balance'] as int : 0;
      
      await txn.insert('inventory', {
        'trays_in': crates,
        'trays_out': 0,
        'balance': currentBalance + crates,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return count;
    });
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
