import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/inventory.dart';
import '../models/fixed_asset.dart';
import '../models/product.dart';

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
      version: 29,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database upgrading from $oldVersion to $newVersion');

    // Ensure all columns exist for all versions
    await _addColumnIfNotExists(
      db,
      'receipt_settings',
      'remembered_printer_address',
      'TEXT',
    );
    await _addColumnIfNotExists(
      db,
      'purchases',
      'other_cost_description',
      'TEXT',
    );
    await _addColumnIfNotExists(
      db,
      'purchases',
      'payment_method',
      'TEXT DEFAULT "Other"',
    );

    // Ensure existing data is not NULL after migration

    if (oldVersion < 18) {
      debugPrint('Running migration to 18');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          created_at TEXT NOT NULL,
          payment_method TEXT,
          other_details TEXT,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
        )
      ''');
      await _addColumnIfNotExists(
        db,
        'sale_payments',
        'payment_method',
        'TEXT',
      );
      await _addColumnIfNotExists(db, 'sale_payments', 'other_details', 'TEXT');
      await _addColumnIfNotExists(
        db,
        'receipt_settings',
        'default_exchange_rate',
        'REAL DEFAULT 1.0',
      );
    }
    if (oldVersion < 19) {
      debugPrint('Running migration to 19');
      await _addColumnIfNotExists(
        db,
        'receipt_settings',
        'default_exchange_rate',
        'REAL DEFAULT 1.0',
      );
    }
    if (oldVersion < 20) {
      debugPrint('Running migration to 20');
      await _addColumnIfNotExists(
        db,
        'receipt_settings',
        'payment_method_charges',
        'TEXT',
      );
    }
    if (oldVersion < 21) {
      debugPrint('Running migration to 21');
      await _addColumnIfNotExists(
        db,
        'sale_payments',
        'charge_amount',
        'REAL DEFAULT 0.0',
      );
      await _addColumnIfNotExists(
        db,
        'sale_payments',
        'charge_description',
        'TEXT',
      );
    }
    if (oldVersion < 22) {
      debugPrint('Running migration to 22');
      await _addColumnIfNotExists(
        db,
        'purchases',
        'other_cost_description',
        'TEXT',
      );
    }

    if (oldVersion < 28) {
      debugPrint('Running migration to 28: Multi-product support');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          unit_name TEXT NOT NULL,
          sub_unit_name TEXT,
          sub_units_per_unit INTEGER NOT NULL DEFAULT 1,
          icon TEXT
        )
      ''');

      // Seed default Eggs product if not exists
      final eggsResult = await db.query('products', where: 'id = 1');
      if (eggsResult.isEmpty) {
        await db.insert('products', {
          'id': 1,
          'name': 'Eggs',
          'unit_name': 'Tray',
          'sub_unit_name': 'Egg',
          'sub_units_per_unit': 30,
        });
      }

      await _addColumnIfNotExists(
        db,
        'purchases',
        'product_id',
        'INTEGER DEFAULT 1',
      );
      await _addColumnIfNotExists(
        db,
        'sales',
        'product_id',
        'INTEGER DEFAULT 1',
      );
      await _addColumnIfNotExists(
        db,
        'inventory',
        'product_id',
        'INTEGER DEFAULT 1',
      );

      // Update existing records to product_id 1
      await db.execute(
        'UPDATE purchases SET product_id = 1 WHERE product_id IS NULL',
      );
      await db.execute(
        'UPDATE sales SET product_id = 1 WHERE product_id IS NULL',
      );
      await db.execute(
        'UPDATE inventory SET product_id = 1 WHERE product_id IS NULL',
      );
    }
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
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
      CREATE TABLE IF NOT EXISTS products (
        id $idType,
        name $textType,
        unit_name $textType,
        sub_unit_name $textTypeNullable,
        sub_units_per_unit $intType DEFAULT 1,
        icon $textTypeNullable
      )
    ''');

    await db.insert('products', {
      'id': 1,
      'name': 'Eggs',
      'unit_name': 'Tray',
      'sub_unit_name': 'Egg',
      'sub_units_per_unit': 30,
    });

    await db.insert('products', {
      'id': 2,
      'name': 'Chickens',
      'unit_name': 'Full Chicken',
      'sub_unit_name': null,
      'sub_units_per_unit': 1,
    });

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
        product_id $intType DEFAULT 1,
        supplier_id $intType,
        trays $intType,
        remaining_eggs $intType,
        buying_price_per_tray $realType,
        transport_cost $realType,
        other_cost $realType,
        other_cost_description TEXT,
        total_cost $realType,
        batch_number TEXT,
        notes $textType,
        created_at $textType,
        latitude $realType,
        longitude $realType,
        currency_code TEXT DEFAULT "USD",
        exchange_rate REAL DEFAULT 1.0,
        payment_method TEXT DEFAULT "Other",
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id $idType,
        product_id $intType DEFAULT 1,
        customer_id $intType,
        trays_sold $intType,
        eggs_sold $intType,
        selling_price_per_tray $realType,
        delivery_cost $realType DEFAULT 0,
        employee_cost $realType DEFAULT 0,
        tax_rate $realType DEFAULT 0,
        tax_amount $realType DEFAULT 0,
        tax_label TEXT,
        is_tax_inclusive INTEGER DEFAULT 0,
        total_revenue $realType,
        total_cost $realType,
        profit $realType,
        amount_paid $realType,
        balance_due $realType,
        notes $textType,
        created_at $textType,
        latitude $realType,
        longitude $realType,
        currency_code TEXT DEFAULT "USD",
        exchange_rate REAL DEFAULT 1.0,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
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
        longitude $realType,
        currency_code TEXT DEFAULT "USD",
        exchange_rate REAL DEFAULT 1.0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id $idType,
        product_id $intType DEFAULT 1,
        trays_in $intType,
        trays_out $intType,
        balance $intType,
        created_at $textType,
        FOREIGN KEY (product_id) REFERENCES products (id)
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
        notes $textTypeNullable,
        currency_code TEXT DEFAULT "USD",
        exchange_rate REAL DEFAULT 1.0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS equity_ledger (
        id $idType,
        type $textType,
        amount $realType,
        notes $textTypeNullable,
        created_at $textType,
        currency_code TEXT DEFAULT "USD",
        exchange_rate REAL DEFAULT 1.0
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
        footer_note TEXT,
        default_tax_rate REAL DEFAULT 1.0,
        default_exchange_rate REAL DEFAULT 1.0,
        logo_path TEXT,
        base_currency TEXT DEFAULT "USD",
        predefined_taxes TEXT,
        payment_method_charges TEXT,
        remembered_printer_address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        payment_method TEXT,
        other_details TEXT,
        charge_amount REAL DEFAULT 0.0,
        charge_description TEXT,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_created_at ON inventory(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_created_at ON purchases(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON expenses(created_at)',
    );
  }

  // --- CRUD Operations ---

  // Products
  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

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
    final product = await getProductById(purchase.productId);
    final ratio = product?.subUnitsPerUnit ?? 30;

    return await db.transaction((txn) async {
      // Initialize remaining sub-units for FIFO tracking
      final updatedPurchase = purchase.copyWith(
        remainingEggs: purchase.crates * ratio,
      );
      final id = await txn.insert('purchases', updatedPurchase.toMap());

      // Update inventory
      final lastInventory = await txn.query(
        'inventory',
        where: 'product_id = ?',
        whereArgs: [purchase.productId],
        orderBy: 'id DESC',
        limit: 1,
      );
      final currentBalance = lastInventory.isNotEmpty
          ? lastInventory.first['balance'] as int
          : 0;

      await txn.insert('inventory', {
        'product_id': purchase.productId,
        'trays_in': purchase.crates,
        'trays_out': 0,
        'balance': currentBalance + purchase.crates,
        'created_at': purchase.createdAt.toIso8601String(),
      });

      return id;
    });
  }

  Future<List<Purchase>> getAllPurchases({int? productId}) async {
    final db = await instance.database;
    final result = await db.query(
      'purchases',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'created_at DESC',
    );
    return result.map((json) => Purchase.fromMap(json)).toList();
  }

  // Sales
  Future<List<Sale>> getSales({
    int limit = 20,
    int offset = 0,
    int? productId,
  }) async {
    final db = await instance.database;
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

  Future<int> createSale(Sale sale) async {
    final db = await instance.database;
    final product = await getProductById(sale.productId);
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

        // Note: pricePerEgg is (totalCost / (crates * ratio))
        totalCOGS +=
            consumed * (purchase.totalCost / (purchase.crates * ratio));
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

  Future<Sale?> getSaleById(int id) async {
    final db = await instance.database;
    final result = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Sale.fromMap(result.first) : null;
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
  Future<int> getInventoryBalance({int? productId}) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['balance'] as int : 0;
  }

  Future<List<Inventory>> getInventoryHistory({int? productId}) async {
    final db = await instance.database;
    final result = await db.query(
      'inventory',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'created_at DESC',
    );
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

  Future<double> getTotalEquity({String? currency}) async {
    final db = await instance.database;
    String where = '';
    List<dynamic> args = [];
    if (currency != null) {
      where = 'WHERE currency_code = ?';
      args.add(currency);
    }
    final result = await db.rawQuery(
      'SELECT SUM(amount * exchange_rate) as total FROM equity_ledger $where',
      args,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Debt Management
  Future<int> addPayment(
    int saleId,
    double amount,
    String method,
    String details, {
    double chargeAmount = 0.0,
    String? chargeDescription,
  }) async {
    final db = await instance.database;
    return await db.insert('sale_payments', {
      'sale_id': saleId,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
      'payment_method': method,
      'other_details': details,
      'charge_amount': chargeAmount,
      'charge_description': chargeDescription,
    });
  }

  Future<List<Map<String, dynamic>>> getPaymentsForSale(int saleId) async {
    final db = await instance.database;
    return await db.query(
      'sale_payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'created_at DESC',
    );
  }

  // Breakdown Methods
  Future<List<Map<String, dynamic>>> getSalesBreakdown(
    DateTime? start,
    DateTime? end, {
    String? currency,
    String? paymentMethod,
    int? productId,
  }) async {
    final db = await instance.database;

    String paymentJoin = '';
    List<String> filters = [];

    if (start != null && end != null) {
      filters.add(
        'date(s.created_at) BETWEEN "${start.toIso8601String().substring(0, 10)}" AND "${end.toIso8601String().substring(0, 10)}"',
      );
    }
    if (currency != null) filters.add('s.currency_code = "$currency"');
    if (productId != null) filters.add('s.product_id = $productId');
    if (paymentMethod != null) {
      paymentJoin = 'JOIN sale_payments sp ON s.id = sp.sale_id';
      filters.add('sp.payment_method = "$paymentMethod"');
    }

    String whereClause = filters.isNotEmpty
        ? 'WHERE ${filters.join(' AND ')}'
        : '';

    return await db.rawQuery(
      'SELECT DISTINCT s.id, s.total_revenue as amount, s.created_at FROM sales s $paymentJoin $whereClause ORDER BY s.created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getExpensesBreakdown(
    DateTime? start,
    DateTime? end, {
    String? currency,
  }) async {
    final db = await instance.database;
    List<String> filters = [];
    if (start != null && end != null) {
      final sStr = start.toIso8601String().substring(0, 10);
      final eStr = end.toIso8601String().substring(0, 10);
      filters.add('date(created_at) BETWEEN "$sStr" AND "$eStr"');
    }
    if (currency != null) {
      filters.add('currency_code = "$currency"');
    }
    String filter = filters.isNotEmpty ? 'WHERE ${filters.join(' AND ')}' : '';
    return await db.rawQuery(
      'SELECT expense_type as name, amount, description, created_at FROM expenses $filter ORDER BY created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getDebtBreakdown({
    String? currency,
    int? productId,
  }) async {
    final db = await instance.database;
    String where = 's.balance_due > 0';
    List<dynamic> args = [];
    if (currency != null) {
      where += ' AND s.currency_code = ?';
      args.add(currency);
    }
    if (productId != null) {
      where += ' AND s.product_id = ?';
      args.add(productId);
    }
    return await db.rawQuery(
      'SELECT s.id, c.name, s.balance_due as amount FROM sales s JOIN customers c ON s.customer_id = c.id WHERE $where',
      args,
    );
  }

  Future<List<Map<String, dynamic>>> getTaxBreakdown(
    DateTime? start,
    DateTime? end, {
    String? currency,
    int? productId,
  }) async {
    final db = await instance.database;
    List<String> filters = ['tax_amount > 0'];
    if (start != null && end != null) {
      filters.add(
        'date(created_at) BETWEEN "${start.toIso8601String().substring(0, 10)}" AND "${end.toIso8601String().substring(0, 10)}"',
      );
    }
    if (currency != null) filters.add('currency_code = "$currency"');
    if (productId != null) filters.add('product_id = $productId');

    String filter = 'WHERE ${filters.join(' AND ')}';
    return await db.rawQuery(
      'SELECT id as sale_id, tax_label, tax_amount FROM sales $filter ORDER BY created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getEquityBreakdown() async {
    final db = await instance.database;
    return await db.query('equity_ledger', orderBy: 'created_at DESC');
  }

  // Metrics
  Future<double> getInventoryValue({String? currency, int? productId}) async {
    final db = await instance.database;
    String where = 'remaining_eggs > 0';
    List<dynamic> args = [];
    if (currency != null) {
      where += ' AND currency_code = ?';
      args.add(currency);
    }
    if (productId != null) {
      where += ' AND product_id = ?';
      args.add(productId);
    }
    final result = await db.query('purchases', where: where, whereArgs: args);
    double totalValue = 0;

    // We need ratio to calculate price per sub-unit if using hardcoded getter
    for (var row in result) {
      final p = Purchase.fromMap(row);
      final prod = await getProductById(p.productId);
      final ratio = prod?.subUnitsPerUnit ?? 30;
      final pricePerSubUnit = p.totalCost / (p.crates * ratio);
      totalValue += (p.remainingEggs * pricePerSubUnit) * p.exchangeRate;
    }
    return totalValue;
  }

  Future<double> getTotalCustomerDebt({
    String? currency,
    int? productId,
  }) async {
    final db = await instance.database;
    String where = 'balance_due > 0';
    List<dynamic> args = [];
    if (currency != null) {
      where += ' AND currency_code = ?';
      args.add(currency);
    }
    if (productId != null) {
      where += ' AND product_id = ?';
      args.add(productId);
    }
    final result = await db.rawQuery(
      'SELECT balance_due, exchange_rate FROM sales WHERE $where',
      args,
    );
    double total = 0;
    for (var row in result) {
      total +=
          (row['balance_due'] as num).toDouble() *
          (row['exchange_rate'] as num).toDouble();
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getInventoryBreakdown({
    int? productId,
  }) async {
    final db = await instance.database;
    final where = productId != null
        ? 'WHERE p.product_id = $productId AND p.remaining_eggs > 0'
        : 'WHERE p.remaining_eggs > 0';
    return await db.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      $where
      ORDER BY p.created_at ASC
    ''');
  }

  // Reports/Calculations
  Future<Map<String, double>> getSummaryInRange(
    DateTime? start,
    DateTime? end, {
    String? currency,
    String? paymentMethod,
    int? productId,
  }) async {
    final db = await instance.database;

    String paymentJoin = '';
    String salesPaymentFilter = '';
    if (paymentMethod != null) {
      paymentJoin = 'JOIN sale_payments sp ON s.id = sp.sale_id';
      salesPaymentFilter = 'sp.payment_method = "$paymentMethod"';
    }

    // --- Filters for purchases ---
    List<String> purchaseFilters = [];
    if (start != null && end != null) {
      final sStr = start.toIso8601String().substring(0, 10);
      final eStr = end.toIso8601String().substring(0, 10);
      purchaseFilters.add('date(created_at) BETWEEN "$sStr" AND "$eStr"');
    }
    if (currency != null) {
      purchaseFilters.add('currency_code = "$currency"');
    }
    if (paymentMethod != null) {
      // Purchases table has payment_method column
      purchaseFilters.add('payment_method = "$paymentMethod"');
    }
    if (productId != null) {
      purchaseFilters.add('product_id = $productId');
    }
    String purchaseWhere = purchaseFilters.isNotEmpty
        ? 'WHERE ${purchaseFilters.join(' AND ')}'
        : '';

    // --- Filters for expenses ---
    List<String> expenseFilters = [];
    if (start != null && end != null) {
      final sStr = start.toIso8601String().substring(0, 10);
      final eStr = end.toIso8601String().substring(0, 10);
      expenseFilters.add('date(created_at) BETWEEN "$sStr" AND "$eStr"');
    }
    if (currency != null) {
      expenseFilters.add('currency_code = "$currency"');
    }
    // DO NOT ADD paymentMethod to expenseFilters as expenses table does not have it
    String expenseWhere = expenseFilters.isNotEmpty
        ? 'WHERE ${expenseFilters.join(' AND ')}'
        : '';

    // --- Filters for sales (s. prefix for sale table, sp. for sale_payments) ---
    List<String> salesFilters = [];
    if (start != null && end != null) {
      final sStr = start.toIso8601String().substring(0, 10);
      final eStr = end.toIso8601String().substring(0, 10);
      salesFilters.add('date(s.created_at) BETWEEN "$sStr" AND "$eStr"');
    }
    if (currency != null) salesFilters.add('s.currency_code = "$currency"');
    if (productId != null) salesFilters.add('s.product_id = $productId');
    if (paymentMethod != null) {
      salesFilters.add(salesPaymentFilter); // Use the sp.payment_method filter
    }
    String salesWhereClause = salesFilters.isNotEmpty
        ? 'WHERE ${salesFilters.join(' AND ')}'
        : '';

    final salesResult = await db.rawQuery(
      'SELECT s.total_revenue, s.profit, s.balance_due, s.tax_amount, s.exchange_rate FROM sales s '
      '$paymentJoin $salesWhereClause',
    );

    // Sum all charges for the range
    final chargesResult = await db.rawQuery(
      'SELECT SUM(sp.charge_amount) as total_charges FROM sale_payments sp '
      'JOIN sales s ON sp.sale_id = s.id $salesWhereClause',
    );
    final totalCharges =
        (chargesResult.first['total_charges'] as num?)?.toDouble() ?? 0.0;

    final expensesSql =
        'SELECT amount, exchange_rate, expense_type FROM expenses $expenseWhere';
    final expensesResult = await db.rawQuery(expensesSql);

    final purchasesSql =
        'SELECT transport_cost, other_cost, exchange_rate FROM purchases $purchaseWhere';
    final purchasesResult = await db.rawQuery(purchasesSql);

    double revenue = 0, profit = 0, balance = 0, taxLiability = 0;
    for (var row in salesResult) {
      final rate = (row['exchange_rate'] as num?)?.toDouble() ?? 1.0;
      revenue += (row['total_revenue'] as num).toDouble() * rate;
      profit += (row['profit'] as num).toDouble() * rate;
      balance += (row['balance_due'] as num).toDouble() * rate;
      taxLiability += (row['tax_amount'] as num).toDouble() * rate;
    }

    // Add charges to revenue and profit
    revenue += totalCharges;
    profit += totalCharges;

    double deliveryCosts = 0,
        employeeCosts = 0,
        otherExpenses = 0,
        opexToSubtract = 0;
    for (var row in expensesResult) {
      final rate = (row['exchange_rate'] as num?)?.toDouble() ?? 1.0;
      final amt = (row['amount'] as num).toDouble() * rate;
      final type = (row['expense_type'] as String).toLowerCase();

      opexToSubtract += amt;
      if (type == 'delivery') {
        deliveryCosts += amt;
      } else if (type == 'employee') {
        employeeCosts += amt;
      } else {
        otherExpenses += amt;
      }
    }

    for (var row in purchasesResult) {
      final rate = (row['exchange_rate'] as num?)?.toDouble() ?? 1.0;
      deliveryCosts += (row['transport_cost'] as num).toDouble() * rate;
      otherExpenses += (row['other_cost'] as num).toDouble() * rate;
    }

    // Calculate Depreciation (Global for now, as assets aren't per-product yet)
    double depreciationExpense = 0.0;
    final allAssetsMaps = await getAllFixedAssets();
    final allAssets = allAssetsMaps.map((m) => FixedAsset.fromMap(m)).toList();

    final rangeStart = start ?? DateTime(2023);
    final rangeEnd = end ?? DateTime.now();

    for (var asset in allAssets) {
      if (asset.purchaseDate.isBefore(rangeEnd.add(const Duration(days: 1)))) {
        final effectiveStart = asset.purchaseDate.isAfter(rangeStart)
            ? asset.purchaseDate
            : rangeStart;
        final daysOwnedInRange = rangeEnd.difference(effectiveStart).inDays + 1;
        if (daysOwnedInRange > 0) {
          final dailyDepr = asset.monthlyDepreciation / 30;
          depreciationExpense += dailyDepr * daysOwnedInRange;
        }
      }
    }

    final inventoryValue = await getInventoryValue(
      currency: currency,
      productId: productId,
    );
    final totalDebt = await getTotalCustomerDebt(
      currency: currency,
      productId: productId,
    );
    final totalEquity = await getTotalEquity(currency: currency);

    final result = {
      'revenue': revenue,
      'gross_profit': profit + deliveryCosts + employeeCosts + otherExpenses,
      'net_profit': profit - opexToSubtract - depreciationExpense,
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
    return result;
  }

  Future<List<Map<String, dynamic>>> getDailyProfitTrend(
    int days, {
    int? productId,
  }) async {
    final db = await instance.database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startDateStr = startDate.toIso8601String().substring(0, 10);

    final where = productId != null
        ? 'date(created_at) >= ? AND product_id = ?'
        : 'date(created_at) >= ?';
    final args = productId != null ? [startDateStr, productId] : [startDateStr];

    final result = await db.rawQuery('''
      SELECT date(created_at) as date, profit, exchange_rate
      FROM sales
      WHERE $where
      ORDER BY date(created_at) ASC
    ''', args);

    Map<String, double> dailyTotals = {};
    for (var row in result) {
      final date = row['date'] as String;
      final val =
          (row['profit'] as num).toDouble() *
          (row['exchange_rate'] as num).toDouble();
      dailyTotals[date] = (dailyTotals[date] ?? 0) + val;
    }

    return dailyTotals.entries
        .map((e) => {'date': e.key, 'daily_profit': e.value})
        .toList();
  }

  Future<List<Map<String, dynamic>>> getExpenseDistribution() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT expense_type, amount, exchange_rate FROM expenses',
    );
    Map<String, double> typeTotals = {};
    for (var row in result) {
      final type = row['expense_type'] as String;
      final val =
          (row['amount'] as num).toDouble() *
          (row['exchange_rate'] as num).toDouble();
      typeTotals[type] = (typeTotals[type] ?? 0) + val;
    }
    return typeTotals.entries
        .map((e) => {'expense_type': e.key, 'total': e.value})
        .toList();
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
      final purchaseResult = await txn.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
      if (purchaseResult.isEmpty) return 0;
      final crates = purchaseResult.first['trays'] as int;
      final count = await txn.delete(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
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
      final saleResult = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );
      if (saleResult.isEmpty) return 0;
      final crates = saleResult.first['trays_sold'] as int;
      final count = await txn.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );
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

    final data = {
      'id': 1,
      'business_name': settings['business_name'],
      'address': settings['address'],
      'tax_id': settings['tax_id'],
      'phone': settings['phone'],
      'email': settings['email'],
      'footer_note': settings['footer_note'],
      'default_tax_rate': settings['default_tax_rate'],
      'default_exchange_rate': settings['default_exchange_rate'],
      'logo_path': settings['logo_path'],
      'base_currency': settings['base_currency'],
      'predefined_taxes': settings['predefined_taxes'] ?? '[]',
      'payment_method_charges': settings['payment_method_charges'] ?? '[]',
      'remembered_printer_address': settings['remembered_printer_address'],
    };

    return await db.insert(
      'receipt_settings',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getDistinctCurrencies() async {
    final db = await instance.database;
    final salesResult = await db.rawQuery(
      'SELECT DISTINCT currency_code FROM sales',
    );
    final expensesResult = await db.rawQuery(
      'SELECT DISTINCT currency_code FROM expenses',
    );
    final purchasesResult = await db.rawQuery(
      'SELECT DISTINCT currency_code FROM purchases',
    );

    final set = <String>{};
    for (var row in salesResult) {
      if (row['currency_code'] != null) set.add(row['currency_code'] as String);
    }
    for (var row in expensesResult) {
      if (row['currency_code'] != null) set.add(row['currency_code'] as String);
    }
    for (var row in purchasesResult) {
      if (row['currency_code'] != null) set.add(row['currency_code'] as String);
    }

    // Ensure base currencies are included
    set.add('USD');
    set.add('ZiG');

    final list = set.toList()..sort();
    return list;
  }

  Future<List<String>> getDistinctPaymentMethods() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT payment_method FROM sale_payments',
    );
    final set = <String>{};
    for (var row in result) {
      if (row['payment_method'] != null) {
        set.add(row['payment_method'] as String);
      }
    }

    // Add default ones
    set.addAll(['Cash', 'Card', 'Ecocash', 'Other']);

    final list = set.toList()..sort();
    return list;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
