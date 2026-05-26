import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/insta_theme.dart';
import '../providers/providers.dart';
import '../widgets/quick_add_dialogs.dart';
import 'suppliers_screen.dart';
import 'customers_screen.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';
import 'expense_screen.dart';
import 'reports_screen.dart';
import 'inventory_breakdown_screen.dart';
import '../features/receipts/presentation/pages/designer_page.dart';
import 'receipt_settings_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final inventoryAsync = ref.watch(inventoryBalanceProvider);
    final dateRange = ref.watch(dashboardDateRangeProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('ZAYI INTEL', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: InstaPalette.textPrimary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: InstaPalette.cardBackground,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: InstaPalette.border, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 12),
                    const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.receipt_long, color: InstaPalette.textPrimary),
                      title: const Text('Receipt Settings', style: TextStyle(color: InstaPalette.textPrimary)),
                      subtitle: const Text('Configure business name, address, and tax info', style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptSettingsScreen()));
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: InstaPalette.textPrimary),
            onSelected: (value) async {
              final notifier = ref.read(dashboardDateRangeProvider.notifier);
              switch (value) {
                case 'today':
                  notifier.setToday();
                  break;
                case 'month':
                  notifier.setThisMonth();
                  break;
                case 'all':
                  notifier.setAllTime();
                  break;
                case 'custom':
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                    initialDateRange: dateRange,
                  );
                  if (picked != null) {
                    notifier.update(picked);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'today', child: Text('Today')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
              const PopupMenuItem(value: 'custom', child: Text('Custom Range...')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(inventoryBalanceProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                dateRange == null 
                    ? 'Period: All Time' 
                    : 'Period: ${DateFormat('MMM dd').format(dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange.end)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Inventory Row
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(
                    'Stock Count', 
                    inventoryAsync, 
                    (d) => '$d Crates',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryBreakdownScreen())),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard(
                    'Stock Value', 
                    summaryAsync, 
                    (d) => '\$${d['inventory_value']?.toStringAsFixed(2)}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryBreakdownScreen())),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              // Revenue & Profit Row
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Revenue', summaryAsync, (d) => '\$${d['revenue']?.toStringAsFixed(2)}')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard('Net Profit', summaryAsync, (d) => '\$${d['net_profit']?.toStringAsFixed(2)}')),
                ],
              ),
              const SizedBox(height: 16),
              // Overhead Row
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Logistics', summaryAsync, (d) => '\$${d['delivery_costs']?.toStringAsFixed(2)}')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard('Wages', summaryAsync, (d) => '\$${d['employee_costs']?.toStringAsFixed(2)}')),
                ],
              ),
              const SizedBox(height: 16),
              // Debt Row
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Total Cust. Debt', summaryAsync, (d) => '\$${d['total_debt']?.toStringAsFixed(2)}')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard('Other Expenses', summaryAsync, (d) => '\$${d['other_expenses']?.toStringAsFixed(2)}')),
                ],
              ),
              const SizedBox(height: 16),
              // Audit Rows
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Tax Liability', summaryAsync, (d) => '\$${d['tax_liability']?.toStringAsFixed(2)}')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard('Depreciation', summaryAsync, (d) => '\$${d['depreciation']?.toStringAsFixed(2)}')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Owner Equity', summaryAsync, (d) => '\$${d['total_equity']?.toStringAsFixed(2)}')),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildActionCard(context, 'Suppliers', Icons.local_shipping, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionCard(context, 'Customers', Icons.people, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen())))),
                ],
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Text('QUICK ACTIONS', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: InstaPalette.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  _buildLargeButton(context, 'NEW PURCHASE', Icons.shopping_cart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseFormPage()))),
                  const SizedBox(height: 12),
                  _buildLargeButton(context, 'NEW SALE', Icons.sell, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleFormPage()))),
                  const SizedBox(height: 12),
                  _buildLargeButton(context, 'RECORD EXPENSE', Icons.money_off, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen()))),
                  const SizedBox(height: 12),
                  _buildLargeButton(context, 'RECORD EQUITY', Icons.account_balance_wallet, () => QuickAddDialogs.showEquityDialog(context, ref)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildLargeButton(context, 'SUPPLIER', Icons.person_add, () => QuickAddDialogs.showAddSupplierDialog(context, ref))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildLargeButton(context, 'CUSTOMER', Icons.person_add_alt_1, () => QuickAddDialogs.showAddCustomerDialog(context, ref))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('REPORTS', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: InstaPalette.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              _buildLargeButton(context, 'RECEIPT DESIGNER', Icons.design_services, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DesignerPage()))),
              const SizedBox(height: 12),
              _buildLargeButton(context, 'VIEW REPORTS', Icons.analytics, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, AsyncValue<dynamic> asyncValue, String Function(dynamic) dataMapper, {VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      color: InstaPalette.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: InstaPalette.textSecondary)),
              const SizedBox(height: 8),
              asyncValue.when(
                data: (d) => Text(dataMapper(d), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, s) {
                  debugPrint('Dashboard card error: $e');
                  return const Icon(Icons.error_outline, color: Colors.red, size: 20);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: InstaPalette.textPrimary,
        foregroundColor: InstaPalette.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(150, 40),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: InstaPalette.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 24, color: InstaPalette.textPrimary),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}