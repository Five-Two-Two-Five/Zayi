import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../theme/insta_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Reports & Export', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('FINANCIAL INTELLIGENCE'),
            const SizedBox(height: 12),
            _buildMasterCard(context),
            const SizedBox(height: 32),
            _buildSectionHeader('EXPORT DATA'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildExportCard(context, 'Purchases', 'purchases', Icons.shopping_cart),
                _buildExportCard(context, 'Sales', 'sales', Icons.sell),
                _buildExportCard(context, 'Expenses', 'expenses', Icons.money_off),
                _buildExportCard(context, 'Suppliers', 'suppliers', Icons.local_shipping),
                _buildExportCard(context, 'Customers', 'customers', Icons.people),
                _buildExportCard(context, 'Inventory', 'inventory', Icons.inventory),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary, letterSpacing: 1.2));
  }

  Widget _buildMasterCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: InstaPalette.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.auto_graph, color: Colors.white, size: 32),
        title: const Text('Master Financial Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: const Text('Unified data for Time-Series analysis', style: TextStyle(color: Colors.white70, fontSize: 12)),
        onTap: () async {
          try {
            await ExportService.exportTimeSeriesData();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Master Log Exported')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, String title, String table, IconData icon) {
    return InkWell(
      onTap: () async {
        try {
          await ExportService.exportToCsv(table);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title Export Successful')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting $table: $e')));
        }
      },
      child: Card(
        elevation: 0,
        color: InstaPalette.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: InstaPalette.textPrimary, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
          ],
        ),
      ),
    );
  }
}
