import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/insta_theme.dart';
import '../providers/providers.dart';
import '../widgets/quick_add_dialogs.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';
import 'expense_screen.dart';
import 'inventory_breakdown_screen.dart';
import 'receipt_settings_screen.dart';
import '../database/database_helper.dart';
import '../widgets/generic_breakdown_screen.dart';
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
              const SizedBox(height: 24),

              // --- PERFORMANCE SECTION ---
              _buildSectionHeader('PERFORMANCE'),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(
                    'Total Revenue', 
                    summaryAsync, 
                    (d) => '\$${d['revenue']?.toStringAsFixed(2)}',
                    isPrimary: true,
                    onTap: () async {
                      final items = await DatabaseHelper.instance.getSalesBreakdown(dateRange?.start, dateRange?.end);
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericBreakdownScreen(
                        title: 'Revenue Breakdown',
                        items: items,
                        itemBuilder: (context, item) => Card(
                          child: ListTile(
                            title: Text('Sale #${item['id']}'),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(item['created_at']))),
                            trailing: Text('\$${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )));
                    },
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard(
                    'Net Profit', 
                    summaryAsync, 
                    (d) => '\$${d['net_profit']?.toStringAsFixed(2)}',
                    isPrimary: true,
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // --- OPERATIONS SECTION ---
              _buildSectionHeader('OPERATIONS'),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(
                    'Logistics', 
                    summaryAsync, 
                    (d) => '\$${d['delivery_costs']?.toStringAsFixed(2)}',
                    onTap: () async {
                      final items = await DatabaseHelper.instance.getExpensesBreakdown(dateRange?.start, dateRange?.end);
                      final filtered = items.where((i) => i['name'] == 'Delivery').toList();
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericBreakdownScreen(
                        title: 'Logistics Breakdown',
                        items: filtered,
                        itemBuilder: (context, item) => Card(
                          child: ListTile(
                            title: Text(item['description']),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(item['created_at']))),
                            trailing: Text('\$${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )));
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard(
                    'Wages', 
                    summaryAsync, 
                    (d) => '\$${d['employee_costs']?.toStringAsFixed(2)}',
                    onTap: () async {
                      final items = await DatabaseHelper.instance.getExpensesBreakdown(dateRange?.start, dateRange?.end);
                      final filtered = items.where((i) => i['name'] == 'Employee').toList();
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericBreakdownScreen(
                        title: 'Wages Breakdown',
                        items: filtered,
                        itemBuilder: (context, item) => Card(
                          child: ListTile(
                            title: Text(item['description']),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(item['created_at']))),
                            trailing: Text('\$${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )));
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard(
                    'Depreciation', 
                    summaryAsync, 
                    (d) => '\$${d['depreciation']?.toStringAsFixed(2)}',
                    onTap: () async {
                      final items = await DatabaseHelper.instance.getAllFixedAssets();
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericBreakdownScreen(
                        title: 'Depreciation Breakdown',
                        items: items,
                        itemBuilder: (context, item) => Card(
                          child: ListTile(
                            title: Text(item['name']),
                            subtitle: Text('Purchase: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(item['purchase_date']))}'),
                            trailing: Text('\$${(item['purchase_price'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )));
                    },
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // --- FINANCIAL HEALTH ---
              _buildSectionHeader('FINANCIAL HEALTH'),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(
                    'Cust. Debt', 
                    summaryAsync, 
                    (d) => '\$${d['total_debt']?.toStringAsFixed(2)}',
                    onTap: () async {
                      final items = await DatabaseHelper.instance.getDebtBreakdown();
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericBreakdownScreen(
                        title: 'Debt Breakdown',
                        items: items,
                        itemBuilder: (context, item) => Card(
                          child: ListTile(
                            title: Text(item['name']),
                            subtitle: Text('Sale ID: ${item['id']}'),
                            trailing: Text('\$${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                        ),
                      )));
                    },
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard(
                    'Owner Equity', 
                    summaryAsync, 
                    (d) => '\$${d['total_equity']?.toStringAsFixed(2)}',
                    onTap: () async {
                      final items = await DatabaseHelper.instance.getEquityBreakdown();
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericBreakdownScreen(
                        title: 'Equity Breakdown',
                        items: items,
                        itemBuilder: (context, item) => Card(
                          child: ListTile(
                            title: Text(item['type']),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(item['created_at']))),
                            trailing: Text('\$${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )));
                    },
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Tax Liability', summaryAsync, (d) => '\$${d['tax_liability']?.toStringAsFixed(2)}')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard(
                    'Other Expenses', 
                    summaryAsync, 
                    (d) => '\$${d['other_expenses']?.toStringAsFixed(2)}',
                    onTap: () async {
                      final items = await DatabaseHelper.instance.getExpensesBreakdown(dateRange?.start, dateRange?.end);
                      final filtered = items.where((i) => i['name'] != 'Delivery' && i['name'] != 'Employee').toList();
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericBreakdownScreen(
                        title: 'Other Expenses',
                        items: filtered,
                        itemBuilder: (context, item) => Card(
                          child: ListTile(
                            title: Text(item['name']),
                            subtitle: Text(item['description']),
                            trailing: Text('\$${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )));
                    },
                  )),
                ],
              ),

              // --- QUICK ACTIONS ---
              _buildSectionHeader('QUICK ACTIONS'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildLargeButton(context, 'NEW SALE', Icons.sell, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleFormPage()))),
                  _buildLargeButton(context, 'NEW PURCHASE', Icons.shopping_cart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseFormPage()))),
                  _buildLargeButton(context, 'EXPENSE', Icons.money_off, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen()))),
                  _buildLargeButton(context, 'EQUITY', Icons.account_balance_wallet, () => QuickAddDialogs.showEquityDialog(context, ref)),
                ],
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: InstaPalette.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 24, height: 2, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, AsyncValue<dynamic> asyncValue, String Function(dynamic) dataMapper, {VoidCallback? onTap, bool isPrimary = false}) {
    return Card(
      elevation: 0,
      color: isPrimary ? InstaPalette.textPrimary : InstaPalette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: isPrimary ? Colors.transparent : InstaPalette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isPrimary ? 24 : 16, horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontSize: 11, 
                      color: isPrimary ? Colors.white70 : InstaPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  asyncValue.when(
                    data: (d) => Text(
                      dataMapper(d), 
                      style: TextStyle(
                        fontSize: isPrimary ? 20 : 14, 
                        fontWeight: FontWeight.bold, 
                        color: isPrimary ? Colors.white : InstaPalette.textPrimary,
                      ),
                    ),
                    loading: () => SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: isPrimary ? Colors.white : InstaPalette.accent),
                    ),
                    error: (e, s) {
                      debugPrint('Dashboard card error: $e');
                      return const Icon(Icons.error_outline, color: Colors.red, size: 20);
                    },
                  ),
                ],
              ),
              if (onTap != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.chevron_right, size: 16, color: isPrimary ? Colors.white70 : InstaPalette.textSecondary),
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
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
