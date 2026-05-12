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

    String csvData = Csv().encode(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$tableName.csv';
    final file = File(path);

    await file.writeAsString(csvData);
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'Exported $tableName records',
      ),
    );
  }
}
