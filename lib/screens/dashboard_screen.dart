import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/quick_add_dialogs.dart';
import 'suppliers_screen.dart';
import 'customers_screen.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';
import 'expense_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final inventoryAsync = ref.watch(inventoryBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EGG TRADER DASHBOARD'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Stock',
                    inventoryAsync.when(
                      data: (d) => '$d Crates',
                      loading: () => '...',
                      error: (e, s) => 'Error',
                    ),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Today\'s Profit',
                    summaryAsync.when(
                      data: (d) => '\$${d['profit']?.toStringAsFixed(2)}',
                      loading: () => '...',
                      error: (e, s) => 'Error',
                    ),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Today\'s Sales',
                    summaryAsync.when(
                      data: (d) => '\$${d['revenue']?.toStringAsFixed(2)}',
                      loading: () => '...',
                      error: (e, s) => 'Error',
                    ),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Expenses',
                    summaryAsync.when(
                      data: (d) => '\$${d['expenses']?.toStringAsFixed(2)}',
                      loading: () => '...',
                      error: (e, s) => 'Error',
                    ),
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildLargeButton(
              context,
              'NEW PURCHASE',
              Icons.shopping_cart,
              Colors.green,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())),
            ),
            const SizedBox(height: 12),
            _buildLargeButton(
              context,
              'NEW SALE',
              Icons.sell,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleScreen())),
            ),
            const SizedBox(height: 12),
            _buildLargeButton(
              context,
              'RECORD EXPENSE',
              Icons.money_off,
              Colors.red,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLargeButton(
                    context,
                    'QUICK SUPPLIER',
                    Icons.person_add,
                    Colors.teal,
                    () => QuickAddDialogs.showAddSupplierDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLargeButton(
                    context,
                    'QUICK CUSTOMER',
                    Icons.person_add_alt_1,
                    Colors.indigo,
                    () => QuickAddDialogs.showAddCustomerDialog(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Suppliers List',
                    Icons.local_shipping,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Customers List',
                    Icons.people,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLargeButton(
              context,
              'REPORTS & EXPORT',
              Icons.analytics,
              Colors.blueGrey,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(inventoryBalanceProvider);
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.orange),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
