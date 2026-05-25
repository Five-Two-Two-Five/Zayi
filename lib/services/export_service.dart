import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class ExportService {
  static Future<void> exportToCsv(String tableName) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> queryResult = await db.query(tableName);

    if (queryResult.isEmpty) return;

    List<List<dynamic>> rows = [];

    // Header
    rows.add(queryResult.first.keys.toList());

    // Data
    for (var row in queryResult) {
      rows.add(row.values.toList());
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$tableName.csv';
    final file = File(path);

    await file.writeAsString(csvData);
    
    await SharePlus.shareXFiles(
      [XFile(path)],
      text: 'Exported $tableName records',
    );
  }

  /// Exports a unified "Master Financial Log" optimized for Time Series analysis.
  /// Joins Sales with Customers, Purchases with Suppliers, and includes Expenses.
  static Future<void> exportTimeSeriesData() async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Unified structure: [Timestamp, Category, SubCategory, EntityName, Amount, Quantity, Profit, BalanceDue]
    List<List<dynamic>> rows = [
      ['Timestamp', 'Category', 'SubCategory', 'Entity_Name', 'Amount_Value', 'Quantity_Crates', 'Profit', 'Balance_Due']
    ];

    // --- Fetch Sales (Revenue) ---
    final sales = await db.rawQuery('''
      SELECT s.created_at, c.name as entity_name, s.total_revenue, s.trays_sold, s.profit, s.balance_due 
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      ORDER BY s.created_at ASC
    ''');
    for (var s in sales) {
      rows.add([
        s['created_at'],
        'Revenue',
        'Sale',
        s['entity_name'] ?? 'Walk-in',
        s['total_revenue'],
        s['trays_sold'],
        s['profit'],
        s['balance_due'],
      ]);
    }

    // --- Fetch Purchases (Cost) ---
    final purchases = await db.rawQuery('''
      SELECT p.created_at, s.name as entity_name, p.total_cost, p.trays
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      ORDER BY p.created_at ASC
    ''');
    for (var p in purchases) {
      rows.add([
        p['created_at'],
        'Cost',
        'Purchase',
        p['entity_name'] ?? 'Unknown',
        - (p['total_cost'] as num), // Negative for cost
        p['trays'],
        0.0, // Purchases don't have "profit" directly
        0.0,
      ]);
    }

    // --- Fetch Expenses (Overhead) ---
    final expenses = await db.query('expenses', orderBy: 'created_at ASC');
    for (var e in expenses) {
      rows.add([
        e['created_at'],
        'Overhead',
        e['expense_type'],
        e['employee_name'] ?? e['description'] ?? 'General',
        - (e['amount'] as num), // Negative for cost
        0, // No quantity for general expenses
        0.0,
        0.0,
      ]);
    }

    // Sort all rows (excluding header) by timestamp
    final header = rows.removeAt(0);
    rows.sort((a, b) => (a[0] as String).compareTo(b[0] as String));
    rows.insert(0, header);

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Zayi_Financial_Time_Series.csv';
    final file = File(path);

    await file.writeAsString(csvData);
    
    await SharePlus.shareXFiles(
      [XFile(path)],
      text: 'Zayi Master Financial Log for Time Series Analysis',
    );
  }
}
