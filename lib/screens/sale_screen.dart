import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';

class SaleScreen extends ConsumerStatefulWidget {
  const SaleScreen({super.key});

  @override
  ConsumerState<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends ConsumerState<SaleScreen> {
  final _cratesController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();

  // Quick Add Customer controllers
  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isQuickAddingCustomer = false;

  void _showAddSaleDialog() {
    // Start location fetch early
    final locationFuture = LocationService.getCurrentLocation();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final customersAsync = ref.watch(customersProvider);

            return AlertDialog(
              title: const Text('New Sale'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
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
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                              ),
                              initialValue: _isQuickAddingCustomer
                                  ? 'ADD_NEW'
                                  : _selectedCustomer,
                              items: [
                                ...list.map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name),
                                  ),
                                ),
                                const DropdownMenuItem(
                                  value: 'ADD_NEW',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add New Customer',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: _isSaving
                                  ? null
                                  : (val) {
                                      if (val == 'ADD_NEW') {
                                        setState(() {
                                          _isQuickAddingCustomer = true;
                                          _selectedCustomer = null;
                                        });
                                      } else {
                                        setState(() {
                                          _isQuickAddingCustomer = false;
                                          _selectedCustomer = val as Customer;
                                        });
                                      }
                                    },
                            ),
                            if (_isQuickAddingCustomer) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _newNameController,
                                decoration: const InputDecoration(
                                  labelText: 'New Customer Name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                enabled: !_isSaving,
                              ),
                              TextField(
                                controller: _newPhoneController,
                                decoration: const InputDecoration(
                                  labelText: 'New Customer Phone',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                                enabled: !_isSaving,
                              ),
                              const Divider(),
                            ],
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Error loading customers'),
                    ),
                    TextField(
                      controller: _cratesController,
                      decoration: const InputDecoration(
                        labelText: 'Crates Sold',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isSaving,
                    ),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per Crate',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isSaving,
                    ),
                    TextField(
                      controller: _paidController,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isSaving,
                    ),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      enabled: !_isSaving,
                    ),
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
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          _isQuickAddingCustomer = false;
                          _selectedCustomer = null;
                          Navigator.pop(context);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final cratesCount = int.tryParse(
                            _cratesController.text,
                          );
                          final price = double.tryParse(_priceController.text);
                          final paid =
                              double.tryParse(
                                _paidController.text.isEmpty
                                    ? '0'
                                    : _paidController.text,
                              ) ??
                              0.0;

                          if ((!_isQuickAddingCustomer &&
                                  _selectedCustomer == null) ||
                              (_isQuickAddingCustomer &&
                                  _newNameController.text.isEmpty) ||
                              cratesCount == null ||
                              price == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all required fields correctly',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => _isSaving = true);
                          try {
                            // 1. Handle Quick Add Customer if needed
                            if (_isQuickAddingCustomer) {
                              final newCustomer = Customer(
                                name: _newNameController.text,
                                phone: _newPhoneController.text,
                                location: '',
                                notes: 'Quick added during sale',
                                createdAt: DateTime.now(),
                              );
                              final id = await DatabaseHelper.instance
                                  .createCustomer(newCustomer);
                              _selectedCustomer = newCustomer.copyWith(id: id);
                              await ref
                                  .read(customersProvider.notifier)
                                  .refresh();
                            }

                            final revenue = cratesCount * price;
                            final pos = await locationFuture;

                            final sale = Sale(
                              customerId: _selectedCustomer!.id!,
                              cratesSold: cratesCount,
                              eggsSold: 0,
                              sellingPricePerCrate: price,
                              deliveryCost: 0,
                              employeeCost: 0,
                              totalRevenue: revenue,
                              totalCost: 0, // Calculated by FIFO in DB helper
                              profit: 0, // Calculated by FIFO in DB helper
                              amountPaid: paid,
                              balanceDue: revenue - paid,
                              notes: _notesController.text,
                              createdAt: _selectedDate,
                              latitude: pos?.latitude ?? 0.0,
                              longitude: pos?.longitude ?? 0.0,
                            );

                            await DatabaseHelper.instance.createSale(sale);
                            ref.read(salesProvider.notifier).refresh();
                            ref.invalidate(inventoryBalanceProvider);
                            ref.invalidate(dashboardSummaryProvider);

                            _cratesController.clear();
                            _priceController.clear();
                            _paidController.clear();
                            _notesController.clear();
                            _newNameController.clear();
                            _newPhoneController.clear();
                            _isQuickAddingCustomer = false;
                            _selectedCustomer = null;
                            _selectedDate = DateTime.now();

                            if (!context.mounted) return;
                            Navigator.pop(context);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          } finally {
                            if (context.mounted)
                              setState(() => _isSaving = false);
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(
                          '${s.cratesSold} Crates @ \$${s.sellingPricePerCrate}',
                        ),
                        subtitle: Text(
                          'Revenue: \$${s.totalRevenue.toStringAsFixed(2)}\nProfit: \$${s.profit.toStringAsFixed(2)}\nDue: \$${s.balanceDue.toStringAsFixed(2)}',
                        ),
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
