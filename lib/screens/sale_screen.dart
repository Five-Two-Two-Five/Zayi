import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';
import '../features/receipts/services/receipt_mapper.dart';
import '../features/receipts/presentation/pages/designer_page.dart';
import '../theme/insta_theme.dart';
import '../widgets/full_page_add_dialog.dart';

class SaleScreen extends ConsumerStatefulWidget {
  const SaleScreen({super.key});

  @override
  ConsumerState<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends ConsumerState<SaleScreen> {
  void _showAddSaleDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SaleFormPage()));
  }

  void _showSettleDebtDialog(Sale sale) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settle Debt', style: TextStyle(color: InstaPalette.textPrimary)),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Amount to Pay', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: InstaPalette.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0 || amount > sale.balanceDue) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid amount')),
                  );
                  return;
                }

                final updatedSale = sale.copyWith(
                  amountPaid: sale.amountPaid + amount,
                  balanceDue: sale.balanceDue - amount,
                );

                await DatabaseHelper.instance.updateSale(updatedSale);
                ref.read(salesProvider.notifier).refresh();
                ref.invalidate(dashboardSummaryProvider);

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: InstaPalette.textPrimary, foregroundColor: InstaPalette.background),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Sales', style: TextStyle(color: InstaPalette.textPrimary)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: salesAsync.when(
        data: (sales) => sales.isEmpty
            ? const Center(child: Text('No sales recorded.', style: TextStyle(color: InstaPalette.textSecondary)))
            : ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final s = sales[index];
                  return Dismissible(
                    key: Key('sale_${s.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await DatabaseHelper.instance.deleteSale(s.id!);
                      ref.read(salesProvider.notifier).refresh();
                      ref.invalidate(inventoryBalanceProvider);
                      ref.invalidate(dashboardSummaryProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sale deleted and inventory adjusted',
                            ),
                          ),
                        );
                      }
                    },
                    child: Card(
                      color: InstaPalette.cardBackground,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
                      elevation: 0,
                      child: ListTile(
                        title: Text(
                          '${s.cratesSold} Crates @ \$${s.sellingPricePerCrate}',
                          style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Revenue: \$${s.totalRevenue.toStringAsFixed(2)}\nProfit: \$${s.profit.toStringAsFixed(2)}\nDue: \$${s.balanceDue.toStringAsFixed(2)}',
                          style: const TextStyle(color: InstaPalette.textSecondary),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (s.balanceDue > 0)
                              IconButton(
                                icon: const Icon(Icons.attach_money, color: Colors.green),
                                onPressed: () => _showSettleDebtDialog(s),
                              ),
                            IconButton(
                              icon: const Icon(Icons.print, color: InstaPalette.accent),
                              onPressed: () async {
                                final customers = await DatabaseHelper.instance.getAllCustomers();
                                final customer = customers.firstWhere(
                                  (c) => c.id == s.customerId,
                                  orElse: () => Customer(
                                    id: s.customerId,
                                    name: 'Unknown Customer',
                                    phone: '',
                                    location: '',
                                    notes: '',
                                    createdAt: DateTime.now(),
                                  ),
                                );

                                final receiptData = ReceiptMapper.fromSale(s, customer);
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DesignerPage(transactionData: receiptData),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: InstaPalette.accent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSaleDialog,
        backgroundColor: InstaPalette.textPrimary,
        child: const Icon(Icons.add_shopping_cart, color: InstaPalette.background),
      ),
    );
  }
}

class SaleFormPage extends ConsumerStatefulWidget {
  const SaleFormPage({super.key});

  @override
  ConsumerState<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends ConsumerState<SaleFormPage> {
  final _cratesController = TextEditingController();
  final _priceController = TextEditingController();
  final _taxRateController = TextEditingController(text: '0');
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();

  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isQuickAddingCustomer = false;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return FullPageAddDialog(
      title: 'New Sale',
      isSaving: _isSaving,
      onSave: () async {
        final cratesCount = int.tryParse(_cratesController.text);
        final price = double.tryParse(_priceController.text);
        final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
        final paid = double.tryParse(_paidController.text.isEmpty ? '0' : _paidController.text) ?? 0.0;

        if ((!_isQuickAddingCustomer && _selectedCustomer == null) ||
            (_isQuickAddingCustomer && _newNameController.text.isEmpty) ||
            cratesCount == null ||
            price == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all required fields correctly')),
          );
          return;
        }

        setState(() => _isSaving = true);
        try {
          Customer? customerToUse = _selectedCustomer;
          if (_isQuickAddingCustomer) {
            final newCustomer = Customer(
              name: _newNameController.text,
              phone: _newPhoneController.text,
              location: '',
              notes: 'Quick added during sale',
              createdAt: DateTime.now(),
            );
            final id = await DatabaseHelper.instance.createCustomer(newCustomer);
            customerToUse = newCustomer.copyWith(id: id);
            await ref.read(customersProvider.notifier).refresh();
          }

          final revenue = cratesCount * price;
          final taxAmount = revenue * (taxRate / 100);
          final pos = await LocationService.getCurrentLocation();

          final sale = Sale(
            customerId: customerToUse!.id!,
            cratesSold: cratesCount,
            eggsSold: 0,
            sellingPricePerCrate: price,
            deliveryCost: 0,
            employeeCost: 0,
            taxRate: taxRate,
            taxAmount: taxAmount,
            totalRevenue: revenue,
            totalCost: 0,
            profit: 0,
            amountPaid: paid,
            balanceDue: revenue - paid,
            notes: _notesController.text,
            createdAt: _selectedDate,
            latitude: pos?.latitude ?? 0.0,
            longitude: pos?.longitude ?? 0.0,
          );

          final id = await DatabaseHelper.instance.createSale(sale);
          ref.read(salesProvider.notifier).refresh();
          ref.invalidate(inventoryBalanceProvider);
          ref.invalidate(dashboardSummaryProvider);

          final finalSale = sale.copyWith(id: id);
          final settings = await ref.read(receiptSettingsProvider.future);
          final receiptData = ReceiptMapper.fromSale(finalSale, customerToUse, settings: settings);
          
          if (!context.mounted) return;
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DesignerPage(transactionData: receiptData),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      },
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
              style: const TextStyle(color: InstaPalette.textPrimary),
            ),
            trailing: const Icon(Icons.calendar_today, color: InstaPalette.textPrimary),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          customersAsync.when(
            data: (list) {
              return Column(
                children: [
                  DropdownButtonFormField<dynamic>(
                    value: _isQuickAddingCustomer ? 'ADD_NEW' : _selectedCustomer,
                    decoration: const InputDecoration(labelText: 'Customer', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
                    items: [
                      ...list.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(color: InstaPalette.textPrimary)))),
                      const DropdownMenuItem(
                        value: 'ADD_NEW',
                        child: Row(children: [Icon(Icons.add, color: InstaPalette.accent), SizedBox(width: 8), Text('Add New Customer', style: TextStyle(color: InstaPalette.accent, fontWeight: FontWeight.bold))]),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == 'ADD_NEW') {
                        setState(() { _isQuickAddingCustomer = true; _selectedCustomer = null; });
                      } else {
                        setState(() { _isQuickAddingCustomer = false; _selectedCustomer = val as Customer; });
                      }
                    },
                  ),
                  if (_isQuickAddingCustomer) ...[
                    TextField(controller: _newNameController, decoration: const InputDecoration(labelText: 'New Customer Name', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
                    TextField(controller: _newPhoneController, decoration: const InputDecoration(labelText: 'New Customer Phone', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.phone),
                    const Divider(),
                  ],
                ],
              );
            },
            loading: () => const CircularProgressIndicator(color: InstaPalette.accent),
            error: (e, s) => const Text('Error loading customers', style: TextStyle(color: Colors.red)),
          ),
          TextField(controller: _cratesController, decoration: const InputDecoration(labelText: 'Crates Sold', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
          TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per Crate', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
          TextField(controller: _taxRateController, decoration: const InputDecoration(labelText: 'Tax Rate (%)', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
          TextField(controller: _paidController, decoration: const InputDecoration(labelText: 'Amount Paid', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
        ],
      ),
    );
  }
}
