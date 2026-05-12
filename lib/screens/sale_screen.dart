import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../services/location_service.dart';

class SaleScreen extends ConsumerStatefulWidget {
  const SaleScreen({super.key});

  @override
  ConsumerState<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends ConsumerState<SaleScreen> {
  final _traysController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController(text: '0');
  final _employeeController = TextEditingController(text: '0');
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isSaving = false;

  void _showAddSaleDialog() {
    // Start location fetch early
    final locationFuture = LocationService.getCurrentLocation();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final customersAsync = ref.watch(customersProvider);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Sale'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    customersAsync.when(
                      data: (list) => DropdownButtonFormField<Customer>(
                        decoration: const InputDecoration(labelText: 'Customer'),
                        initialValue: _selectedCustomer,
                        items: list.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: _isSaving ? null : (val) => setState(() => _selectedCustomer = val),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Error loading customers'),
                    ),
                    TextField(controller: _traysController, decoration: const InputDecoration(labelText: 'Trays Sold'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per Tray'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _deliveryController, decoration: const InputDecoration(labelText: 'Delivery Cost'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _employeeController, decoration: const InputDecoration(labelText: 'Employee Cost'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _paidController, decoration: const InputDecoration(labelText: 'Amount Paid'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes'), enabled: !_isSaving),
                    if (_isSaving) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Saving...'),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    final trays = int.tryParse(_traysController.text);
                    final price = double.tryParse(_priceController.text);
                    final delivery = double.tryParse(_deliveryController.text) ?? 0.0;
                    final employee = double.tryParse(_employeeController.text) ?? 0.0;
                    final paid = double.tryParse(_paidController.text.isEmpty ? '0' : _paidController.text) ?? 0.0;

                    if (_selectedCustomer == null || trays == null || price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields correctly')));
                      return;
                    }

                    setState(() => _isSaving = true);
                    try {
                      final revenue = trays * price;
                      
                      double buyingPrice = 0.0;
                      final purchases = await DatabaseHelper.instance.getAllPurchases();
                      if (purchases.isNotEmpty) {
                        buyingPrice = purchases.first.buyingPricePerTray;
                      }

                      final totalCost = (trays * buyingPrice) + delivery + employee;
                      final profit = revenue - totalCost;
                      final balance = revenue - paid;

                      // Use pre-fetched location
                      final pos = await locationFuture;

                      final sale = Sale(
                        customerId: _selectedCustomer!.id!,
                        traysSold: trays,
                        sellingPricePerTray: price,
                        deliveryCost: delivery,
                        employeeCost: employee,
                        totalRevenue: revenue,
                        totalCost: totalCost,
                        profit: profit,
                        amountPaid: paid,
                        balanceDue: balance,
                        notes: _notesController.text,
                        createdAt: DateTime.now(),
                        latitude: pos?.latitude ?? 0.0,
                        longitude: pos?.longitude ?? 0.0,
                      );

                      await DatabaseHelper.instance.createSale(sale);
                      ref.read(salesProvider.notifier).refresh();
                      ref.invalidate(inventoryBalanceProvider);
                      ref.invalidate(dashboardSummaryProvider);

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                    } finally {
                      if (context.mounted) setState(() => _isSaving = false);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      body: salesAsync.when(
        data: (sales) => sales.isEmpty
            ? const Center(child: Text('No sales recorded.'))
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale deleted and inventory adjusted')));
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('${s.traysSold} Trays @ \$${s.sellingPricePerTray}'),
                        subtitle: Text('Revenue: \$${s.totalRevenue.toStringAsFixed(2)}\nProfit: \$${s.profit.toStringAsFixed(2)}\nDue: \$${s.balanceDue.toStringAsFixed(2)}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.sell, color: Colors.orange),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSaleDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
