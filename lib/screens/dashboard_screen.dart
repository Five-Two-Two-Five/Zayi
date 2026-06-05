import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/insta_theme.dart';
import '../providers/providers.dart';
import '../widgets/quick_add_dialogs.dart';
import '../widgets/dashboard_charts.dart';
import '../models/fixed_asset.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';
import 'expense_screen.dart';
import 'inventory_breakdown_screen.dart';
import '../database/database_helper.dart';
import '../widgets/generic_breakdown_screen.dart';
import 'package:intl/intl.dart';
import 'product_selection_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final inventoryAsync = ref.watch(inventoryBalanceProvider);
    final dateRange = ref.watch(dashboardDateRangeProvider);
    final currencyFilter = ref.watch(dashboardCurrencyFilterProvider);
    final paymentMethodFilter = ref.watch(dashboardPaymentMethodFilterProvider);
    final activeProduct = ref.watch(activeProductProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(inventoryBalanceProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(InstaPalette.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateRange == null 
                        ? 'Period: All Time' 
                        : 'Period: ${DateFormat('MMM dd').format(dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textSecondary),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list, color: InstaPalette.textPrimary, size: 20),
                    onSelected: (value) async {
                      final notifier = ref.read(dashboardDateRangeProvider.notifier);
                      switch (value) {
                        case 'today': notifier.setToday(); break;
                        case 'month': notifier.setThisMonth(); break;
                        case 'all': notifier.setAllTime(); break;
                        case 'custom':
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                            initialDateRange: dateRange,
                          );
                          if (picked != null) notifier.update(picked);
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
              const SizedBox(height: InstaPalette.spacingM),

              // Filters
              Row(
                children: [
                  Expanded(
                    child: ref.watch(currenciesProvider).when(
                      data: (currencies) {
                        final String? selectedCurrency = currencyFilter ?? (currencies.isNotEmpty ? currencies.first : null);
                        return DropdownButtonFormField<String>(
                          value: selectedCurrency,
                          decoration: const InputDecoration(labelText: 'Currency', contentPadding: EdgeInsets.symmetric(horizontal: InstaPalette.spacingS, vertical: InstaPalette.spacingS)),
                          items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => ref.read(dashboardCurrencyFilterProvider.notifier).state = v,
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Error'),
                    ),
                  ),
                  const SizedBox(width: InstaPalette.spacingM),
                  Expanded(
                    child: ref.watch(paymentMethodsProvider).when(
                      data: (methods) => DropdownButtonFormField<String>(
                        value: paymentMethodFilter,
                        decoration: const InputDecoration(labelText: 'Payment Method', contentPadding: EdgeInsets.symmetric(horizontal: InstaPalette.spacingS, vertical: InstaPalette.spacingS)),
                        items: [null, ...methods].map((m) => DropdownMenuItem(value: m, child: Text(m ?? 'All'))).toList(),
                        onChanged: (v) => ref.read(dashboardPaymentMethodFilterProvider.notifier).state = v,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Error'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InstaPalette.spacingL),

              _buildSectionHeader('PERFORMANCE'),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Total Revenue', summaryAsync, (d) => '${currencyFilter ?? 'Total'} ${(d['revenue'] as num? ?? 0).toStringAsFixed(2)}', isPrimary: true)),
                  const SizedBox(width: InstaPalette.spacingM),
                  Expanded(child: _buildSummaryCard('Net Profit', summaryAsync, (d) => '\$${(d['net_profit'] as num? ?? 0).toStringAsFixed(2)}', isPrimary: true)),
                ],
              ),
              const SizedBox(height: InstaPalette.spacingL),

              _buildSectionHeader('OPERATIONS'),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Stock Count', inventoryAsync, (d) => '$d ${activeProduct?.unitName ?? 'Units'}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryBreakdownScreen())))),
                  const SizedBox(width: InstaPalette.spacingM),
                  Expanded(child: _buildSummaryCard('Stock Value', summaryAsync, (d) => '${currencyFilter ?? 'Total'} ${(d['inventory_value'] as num? ?? 0).toStringAsFixed(2)}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryBreakdownScreen())))),
                ],
              ),
              const SizedBox(height: 24),
              
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
                  _buildLargeButton(context, 'EXPENSE', Icons.money_off, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseFormPage()))),
                  _buildLargeButton(context, 'EQUITY', Icons.account_balance_wallet, () => QuickAddDialogs.showEquityDialog(context, ref)),
                ],
              ),
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
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary, letterSpacing: 1.2)),
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
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: isPrimary ? Colors.white70 : InstaPalette.textSecondary)),
              const SizedBox(height: 8),
              asyncValue.when(
                data: (d) => Text(dataMapper(d), style: TextStyle(fontSize: isPrimary ? 20 : 14, fontWeight: FontWeight.bold, color: isPrimary ? Colors.white : InstaPalette.textPrimary)),
                loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, s) => const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
