import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ImportService {
  static Future<int> importFromCsv(String tableName) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return 0;

    final file = File(result.files.single.path!);
    final csvString = await file.readAsString(encoding: utf8);
    
    // Parse CSV
    final List<List<dynamic>> rows = const CsvDecoder().convert(csvString);
    if (rows.isEmpty) return 0;

    final header = rows.removeAt(0);
    final db = await DatabaseHelper.instance.database;
    
    int importedCount = 0;
    
    await db.transaction((txn) async {
      for (var row in rows) {
        if (row.length != header.length) continue;
        
        Map<String, dynamic> data = {};
        for (int i = 0; i < header.length; i++) {
          final columnName = header[i].toString();
          var value = row[i];
          
          // Basic type conversion for numbers if needed, 
          // though sqflite handles dynamic types well.
          // Empty strings should be converted to null if nullable in DB?
          // For now, keep as is.
          data[columnName] = value;
        }
        
        await txn.insert(
          tableName, 
          data, 
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        importedCount++;
      }
    });

    return importedCount;
  }
}
