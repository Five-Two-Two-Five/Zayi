import 'package:flutter/material.dart';
import '../theme/insta_theme.dart';
import 'suppliers_screen.dart';
import 'customers_screen.dart';
import 'assets_screen.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Management', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildManagementCard(context, 'Suppliers', Icons.local_shipping, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen()))),
            _buildManagementCard(context, 'Customers', Icons.people, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()))),
            _buildManagementCard(context, 'Assets', Icons.inventory_2, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetsScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: InstaPalette.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: InstaPalette.textPrimary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textPrimary, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
