import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/inventory.dart';
import '../models/fixed_asset.dart';

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
      version: 10,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ... existing migration logic ...
    if (oldVersion < 5) {
      await _addColumnIfNotExists(db, 'sales', 'delivery_cost', 'REAL DEFAULT 0');
    }
    
    if (oldVersion < 6) {
      await _addColumnIfNotExists(db, 'sales', 'employee_cost', 'REAL DEFAULT 0');
    }

    if (oldVersion < 7) {
      await _addColumnIfNotExists(db, 'expenses', 'latitude', 'REAL DEFAULT 0');
      await _addColumnIfNotExists(db, 'expenses', 'longitude', 'REAL DEFAULT 0');
    }

    if (oldVersion < 8) {
      await _addColumnIfNotExists(db, 'sales', 'tax_rate', 'REAL DEFAULT 0');
      await _addColumnIfNotExists(db, 'sales', 'tax_amount', 'REAL DEFAULT 0');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fixed_assets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          purchase_price REAL NOT NULL,
          purchase_date TEXT NOT NULL,
          useful_life_months INTEGER NOT NULL,
          residual_value REAL NOT NULL,
          notes TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS equity_ledger (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS receipt_settings (
          id INTEGER PRIMARY KEY DEFAULT 1,
          business_name TEXT,
          address TEXT,
          tax_id TEXT,
          phone TEXT,
          email TEXT,
          footer_note TEXT,
          default_tax_rate REAL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    final exists = result.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id $idType,
        name $textType,
        phone $textType,
        location $textType,
        notes $textType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id $idType,
        name $textType,
        phone $textType,
        location $textType,
        notes $textType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
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
      CREATE TABLE IF NOT EXISTS sales (
        id $idType,
        customer_id $intType,
        trays_sold $intType,
        eggs_sold $intType,
        selling_price_per_tray $realType,
        delivery_cost $realType DEFAULT 0,
        employee_cost $realType DEFAULT 0,
        tax_rate $realType DEFAULT 0,
        tax_amount $realType DEFAULT 0,
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
      CREATE TABLE IF NOT EXISTS expenses (
        id $idType,
        expense_type $textType,
        amount $realType,
        description $textType,
        employee_name $textTypeNullable,
        extra_details $textTypeNullable,
        created_at $textType,
        latitude $realType,
        longitude $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id $idType,
        trays_in $intType,
        trays_out $intType,
        balance $intType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fixed_assets (
        id $idType,
        name $textType,
        purchase_price $realType,
        purchase_date $textType,
        useful_life_months $intType,
        residual_value $realType,
        notes $textTypeNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS equity_ledger (
        id $idType,
        type $textType,
        amount $realType,
        notes $textTypeNullable,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipt_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        business_name TEXT,
        address TEXT,
        tax_id TEXT,
        phone TEXT,
        email TEXT,
        footer_note TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_created_at ON inventory(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_created_at ON purchases(created_at)',
    );
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON expenses(created_at)',
    );
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
      final updatedPurchase = purchase.copyWith(
        remainingEggs: purchase.crates * 30,
      );
      final id = await txn.insert('purchases', updatedPurchase.toMap());

      // Update inventory
      final lastInventory = await txn.query(
        'inventory',
        orderBy: 'id DESC',
        limit: 1,
      );
      final currentBalance = lastInventory.isNotEmpty
          ? lastInventory.first['balance'] as int
          : 0;

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
      final lastInventory = await txn.query(
        'inventory',
        orderBy: 'id DESC',
        limit: 1,
      );
      final currentCrateBalance = lastInventory.isNotEmpty
          ? lastInventory.first['balance'] as int
          : 0;

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
        final fallbackResult = await txn.query(
          'purchases',
          orderBy: 'id DESC',
          limit: 1,
        );
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

  Future<int> updateSale(Sale sale) async {
    final db = await instance.database;
    return await db.update(
      'sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
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

  // Fixed Assets
  Future<int> createFixedAsset(Map<String, dynamic> asset) async {
    final db = await instance.database;
    return await db.insert('fixed_assets', asset);
  }

  Future<List<Map<String, dynamic>>> getAllFixedAssets() async {
    final db = await instance.database;
    return await db.query('fixed_assets', orderBy: 'purchase_date DESC');
  }

  Future<int> deleteFixedAsset(int id) async {
    final db = await instance.database;
    return await db.delete('fixed_assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateFixedAsset(FixedAsset asset) async {
    final db = await instance.database;
    return await db.update(
      'fixed_assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  // Equity Ledger
  Future<int> createEquityTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    return await db.insert('equity_ledger', transaction);
  }

  Future<List<Map<String, dynamic>>> getAllEquityTransactions() async {
    final db = await instance.database;
    return await db.query('equity_ledger', orderBy: 'created_at DESC');
  }

  Future<double> getTotalEquity() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT type, SUM(amount) as total FROM equity_ledger GROUP BY type');
    double contribution = 0;
    double drawing = 0;
    for (var row in result) {
      if (row['type'] == 'CONTRIBUTION') contribution = (row['total'] as num).toDouble();
      if (row['type'] == 'DRAWING') drawing = (row['total'] as num).toDouble();
    }
    return contribution - drawing;
  }

  // Debt Management
  Future<int> addPayment(int saleId, double amount) async {
    final db = await instance.database;
    return await db.insert('sale_payments', {
      'sale_id': saleId,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPaymentsForSale(int saleId) async {
    final db = await instance.database;
    return await db.query('sale_payments', where: 'sale_id = ?', whereArgs: [saleId], orderBy: 'created_at DESC');
  }

  // Breakdown Methods
  Future<List<Map<String, dynamic>>> getSalesBreakdown(DateTime? start, DateTime? end) async {
    final db = await instance.database;
    String filter = '';
    if (start != null && end != null) {
      filter = 'WHERE date(created_at) BETWEEN "${start.toIso8601String().substring(0,10)}" AND "${end.toIso8601String().substring(0,10)}"';
    }
    return await db.rawQuery('SELECT id, total_revenue as amount, created_at FROM sales $filter ORDER BY created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getExpensesBreakdown(DateTime? start, DateTime? end) async {
    final db = await instance.database;
    String filter = '';
    if (start != null && end != null) {
      filter = 'WHERE date(created_at) BETWEEN "${start.toIso8601String().substring(0,10)}" AND "${end.toIso8601String().substring(0,10)}"';
    }
    return await db.rawQuery('SELECT expense_type as name, amount, description, created_at FROM expenses $filter ORDER BY created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getDebtBreakdown() async {
    final db = await instance.database;
    return await db.rawQuery('SELECT s.id, c.name, s.balance_due as amount FROM sales s JOIN customers c ON s.customer_id = c.id WHERE s.balance_due > 0');
  }

  Future<List<Map<String, dynamic>>> getEquityBreakdown() async {
    final db = await instance.database;
    return await db.query('equity_ledger', orderBy: 'created_at DESC');
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
    final result = await db.rawQuery(
      'SELECT SUM(balance_due) as total FROM sales',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getInventoryBreakdown() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.remaining_eggs > 0
      ORDER BY p.created_at ASC
    ''');
  }

  // Reports/Calculations
  Future<Map<String, double>> getSummaryInRange(
    DateTime? start,
    DateTime? end,
  ) async {
    final db = await instance.database;

    String dateFilter = '';
    if (start != null && end != null) {
      final sStr = start.toIso8601String().substring(0, 10);
      final eStr = end.toIso8601String().substring(0, 10);
      dateFilter = 'WHERE date(created_at) BETWEEN "$sStr" AND "$eStr"';
    }

    final salesResult = await db.rawQuery(
      'SELECT SUM(total_revenue) as revenue, SUM(profit) as profit, SUM(balance_due) as balance, SUM(tax_amount) as tax FROM sales '
      '$dateFilter',
    );

    final expensesSql = dateFilter.isEmpty
        ? 'SELECT expense_type, SUM(amount) as total FROM expenses GROUP BY expense_type'
        : 'SELECT expense_type, SUM(amount) as total FROM expenses $dateFilter GROUP BY expense_type';

    final expensesResult = await db.rawQuery(expensesSql);

    final purchaseOverheadsResult = await db.rawQuery(
      'SELECT SUM(transport_cost) as transport, SUM(other_cost) as other FROM purchases '
      '$dateFilter',
    );

    double revenue = (salesResult.first['revenue'] as num?)?.toDouble() ?? 0.0;
    double profit = (salesResult.first['profit'] as num?)?.toDouble() ?? 0.0;
    double balance = (salesResult.first['balance'] as num?)?.toDouble() ?? 0.0;
    double taxLiability = (salesResult.first['tax'] as num?)?.toDouble() ?? 0.0;

    double purchaseTransport = (purchaseOverheadsResult.first['transport'] as num?)?.toDouble() ?? 0.0;
    double purchaseOther = (purchaseOverheadsResult.first['other'] as num?)?.toDouble() ?? 0.0;

    double deliveryCosts = purchaseTransport;
    double employeeCosts = 0.0;
    double otherExpenses = purchaseOther;

    double opexToSubtract = 0.0; // Expenses from the 'expenses' table

    for (var row in expensesResult) {
      final type = row['expense_type'] as String;
      final amt = (row['total'] as num?)?.toDouble() ?? 0.0;
      opexToSubtract += amt;
      
      if (type == 'Delivery') {
        deliveryCosts += amt;
      } else if (type == 'Employee') {
        employeeCosts += amt;
      } else {
        otherExpenses += amt;
      }
    }

    // Calculate Depreciation for the range
    double depreciationExpense = 0.0;
    final allAssetsMaps = await getAllFixedAssets();
    final allAssets = allAssetsMaps.map((m) => FixedAsset.fromMap(m)).toList();
    
    final rangeStart = start ?? DateTime(2023);
    final rangeEnd = end ?? DateTime.now();

    for (var asset in allAssets) {
      debugPrint('Debugging Asset: ${asset.name}, Purchase Price: ${asset.purchasePrice}, Monthly Depr: ${asset.monthlyDepreciation}');
      // Check if asset was owned during the range
      if (asset.purchaseDate.isBefore(rangeEnd.add(const Duration(days: 1)))) {
        final effectiveStart = asset.purchaseDate.isAfter(rangeStart) ? asset.purchaseDate : rangeStart;
        final daysOwnedInRange = rangeEnd.difference(effectiveStart).inDays + 1;
        
        if (daysOwnedInRange > 0) {
          // Simple straight-line daily depreciation
          final dailyDepr = asset.monthlyDepreciation / 30;
          final deprForRange = dailyDepr * daysOwnedInRange;
          debugPrint('Asset: ${asset.name}, Days Owned in Range: $daysOwnedInRange, Depr for range: $deprForRange');
          depreciationExpense += deprForRange;
        }
      }
    }

    final inventoryValue = await getInventoryValue();
    final totalDebt = await getTotalCustomerDebt();
    final totalEquity = await getTotalEquity();

    return {
      'revenue': revenue,
      'gross_profit':
          profit +
          deliveryCosts +
          employeeCosts +
          otherExpenses, // Display metric
      'net_profit': profit - opexToSubtract - depreciationExpense, // Correctly avoid double-deducting purchase overheads
      'delivery_costs': deliveryCosts,
      'employee_costs': employeeCosts,
      'other_expenses': otherExpenses,
      'inventory_value': inventoryValue,
      'total_debt': totalDebt,
      'new_debt': balance,
      'tax_liability': taxLiability,
      'depreciation': depreciationExpense,
      'total_equity': totalEquity,
    };
  }

  Future<Map<String, double>> getTodaySummary() async {
    final now = DateTime.now();
    return await getSummaryInRange(now, now);
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
      final purchaseResult = await txn.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
      if (purchaseResult.isEmpty) return 0;

      final crates = purchaseResult.first['trays'] as int;

      // Delete the purchase
      final count = await txn.delete(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      // Update inventory (Reverse the purchase)
      final lastInventory = await txn.query(
        'inventory',
        orderBy: 'id DESC',
        limit: 1,
      );
      final currentBalance = lastInventory.isNotEmpty
          ? lastInventory.first['balance'] as int
          : 0;

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
      final saleResult = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );
      if (saleResult.isEmpty) return 0;

      final crates = saleResult.first['trays_sold'] as int;

      // Delete the sale
      final count = await txn.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );

      // Update inventory (Reverse the sale)
      final lastInventory = await txn.query(
        'inventory',
        orderBy: 'id DESC',
        limit: 1,
      );
      final currentBalance = lastInventory.isNotEmpty
          ? lastInventory.first['balance'] as int
          : 0;

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

  // Receipt Settings
  Future<Map<String, dynamic>> getReceiptSettings() async {
    final db = await instance.database;
    final result = await db.query('receipt_settings', where: 'id = 1');
    if (result.isNotEmpty) return result.first;
    return {};
  }

  Future<int> updateReceiptSettings(Map<String, dynamic> settings) async {
    final db = await instance.database;
    return await db.insert(
      'receipt_settings',
      {'id': 1, ...settings},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
