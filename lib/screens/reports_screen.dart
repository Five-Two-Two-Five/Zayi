import 'package:flutter/material.dart';
import '../services/export_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blueGrey[800],
            child: ListTile(
              leading: const Icon(Icons.analytics, color: Colors.orangeAccent),
              title: const Text('Master Financial Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Unified data for Time-Series analysis (Excel/Python)', style: TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.auto_graph, color: Colors.white),
              onTap: () async {
                try {
                  await ExportService.exportTimeSeriesData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Master Log Exported')));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ),
          const Divider(height: 32),
          _buildExportTile(context, 'Export Purchases', 'purchases', Icons.shopping_cart),
          _buildExportTile(context, 'Export Sales', 'sales', Icons.sell),
          _buildExportTile(context, 'Export Expenses', 'expenses', Icons.money_off),
          _buildExportTile(context, 'Export Suppliers', 'suppliers', Icons.local_shipping),
          _buildExportTile(context, 'Export Customers', 'customers', Icons.people),
          _buildExportTile(context, 'Export Inventory History', 'inventory', Icons.inventory),
        ],
      ),
    );
  }

  Widget _buildExportTile(BuildContext context, String title, String table, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title),
        trailing: const Icon(Icons.download),
        onTap: () async {
          try {
            await ExportService.exportToCsv(table);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title Successful')));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting $table: $e')));
          }
        },
      ),
    );
  }
}
