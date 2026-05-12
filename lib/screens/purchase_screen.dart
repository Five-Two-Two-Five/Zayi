import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  final _traysController = TextEditingController();
  final _priceController = TextEditingController();
  final _transportController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  Supplier? _selectedSupplier;
  bool _isSaving = false;

  void _showAddPurchaseDialog() {
    // Start location fetch early
    final locationFuture = LocationService.getCurrentLocation();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final suppliersAsync = ref.watch(suppliersProvider);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Purchase'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    suppliersAsync.when(
                      data: (list) => DropdownButtonFormField<Supplier>(
                        decoration: const InputDecoration(labelText: 'Supplier'),
                        initialValue: _selectedSupplier,
                        items: list.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                        onChanged: _isSaving ? null : (val) => setState(() => _selectedSupplier = val),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Error loading suppliers'),
                    ),
                    TextField(controller: _traysController, decoration: const InputDecoration(labelText: 'Trays'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per Tray'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _transportController, decoration: const InputDecoration(labelText: 'Transport Cost'), keyboardType: TextInputType.number, enabled: !_isSaving),
                    TextField(controller: _otherController, decoration: const InputDecoration(labelText: 'Other Cost'), keyboardType: TextInputType.number, enabled: !_isSaving),
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
                final transport = double.tryParse(_transportController.text) ?? 0.0;
                final other = double.tryParse(_otherController.text) ?? 0.0;

                if (_selectedSupplier == null || trays == null || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields correctly')));
                  return;
                }

                setState(() => _isSaving = true);
                try {
                  final total = (trays * price) + transport + other;
                  // Use the pre-fetched location
                  final pos = await locationFuture;

                  final purchase = Purchase(
                    supplierId: _selectedSupplier!.id!,
                    trays: trays,
                    buyingPricePerTray: price,
                    transportCost: transport,
                    otherCost: other,
                    totalCost: total,
                    notes: _notesController.text,
                    createdAt: DateTime.now(),
                    latitude: pos?.latitude ?? 0.0,
                    longitude: pos?.longitude ?? 0.0,
                  );

                  await DatabaseHelper.instance.createPurchase(purchase);
                  ref.read(purchasesProvider.notifier).refresh();
                  ref.invalidate(inventoryBalanceProvider);
                  ref.invalidate(dashboardSummaryProvider);
                  
                  _traysController.clear();
                  _priceController.clear();
                  _transportController.text = '0';
                  _otherController.text = '0';
                  _notesController.clear();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final purchasesAsync = ref.watch(purchasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      body: purchasesAsync.when(
        data: (purchases) => purchases.isEmpty
            ? const Center(child: Text('No purchases recorded.'))
            : ListView.builder(
                itemCount: purchases.length,
                itemBuilder: (context, index) {
                  final p = purchases[index];
                  return Dismissible(
                    key: Key('purchase_${p.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await DatabaseHelper.instance.deletePurchase(p.id!);
                      ref.read(purchasesProvider.notifier).refresh();
                      ref.invalidate(inventoryBalanceProvider);
                      ref.invalidate(dashboardSummaryProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase deleted and inventory adjusted')));
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('${p.trays} Trays @ \$${p.buyingPricePerTray}'),
                        subtitle: Text('Total: \$${p.totalCost.toStringAsFixed(2)}\n${DateFormat('yyyy-MM-dd HH:mm').format(p.createdAt)}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.shopping_bag, color: Colors.green),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPurchaseDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
