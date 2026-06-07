import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';
import '../features/receipts/services/receipt_mapper.dart';
import '../features/receipts/presentation/pages/designer_page.dart';
import '../theme/insta_theme.dart';
import '../widgets/full_page_add_dialog.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  void _showAddPurchaseDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseFormPage()));
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final activeProduct = ref.watch(activeProductProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      body: purchasesAsync.when(
        data: (purchases) => purchases.isEmpty
            ? const Center(child: Text('No purchases recorded.', style: TextStyle(color: InstaPalette.textSecondary)))
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Purchase deleted and inventory adjusted',
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
                          '${p.crates} ${activeProduct?.unitName ?? 'Units'} @ ${p.currencyCode} ${p.buyingPricePerCrate}',
                          style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Total: ${p.currencyCode} ${p.totalCost.toStringAsFixed(2)}\n${DateFormat('yyyy-MM-dd HH:mm').format(p.createdAt)}',
                          style: const TextStyle(color: InstaPalette.textSecondary),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.print, color: InstaPalette.accent),
                          onPressed: () async {
                            final suppliers = await DatabaseHelper.instance.getAllSuppliers();
                            final supplier = suppliers.firstWhere(
                              (s) => s.id == p.supplierId,
                              orElse: () => Supplier(
                                id: p.supplierId,
                                name: 'Unknown Supplier',
                                phone: '',
                                location: '',
                                notes: '',
                                createdAt: DateTime.now(),
                              ),
                            );

                            final receiptData = ReceiptMapper.fromPurchase(p, supplier);
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DesignerPage(
                                  transactionData: receiptData,
                                  isReadOnly: true,
                                ),
                              ),
                            );
                          },
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
        onPressed: _showAddPurchaseDialog,
        backgroundColor: InstaPalette.textPrimary,
        child: const Icon(Icons.add_shopping_cart, color: InstaPalette.background),
      ),
    );
  }
}

class PurchaseFormPage extends ConsumerStatefulWidget {
  const PurchaseFormPage({super.key});

  @override
  ConsumerState<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends ConsumerState<PurchaseFormPage> {
  final _cratesController = TextEditingController();
  final _priceController = TextEditingController();
  final _transportController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  final _otherDescriptionController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();
  final _exchangeRateController = TextEditingController(text: '1.0');

  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();

  Supplier? _selectedSupplier;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isQuickAddingSupplier = false;
  String _currencyCode = 'USD';
  double _exchangeRate = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(receiptSettingsProvider.future);
    setState(() {
      _currencyCode = settings.baseCurrency;
      _exchangeRate = settings.defaultExchangeRate;
      _exchangeRateController.text = settings.defaultExchangeRate.toString();
    });
  }

  void _generateBatchNumber() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(_selectedDate);
    final timeStr = DateFormat('HHmm').format(now);
    _batchController.text = 'B-$dateStr-$timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final settingsAsync = ref.watch(receiptSettingsProvider);
    final activeProduct = ref.watch(activeProductProvider);

    return FullPageAddDialog(
      title: 'New ${activeProduct?.name ?? 'Purchase'}',
      isSaving: _isSaving,
      onSave: () async {
        final cratesCount = int.tryParse(_cratesController.text);
        final price = double.tryParse(_priceController.text);
        final transport = double.tryParse(_transportController.text) ?? 0.0;
        final other = double.tryParse(_otherController.text) ?? 0.0;

        if ((!_isQuickAddingSupplier && _selectedSupplier == null) ||
            (_isQuickAddingSupplier && _newNameController.text.isEmpty) ||
            cratesCount == null ||
            price == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all required fields correctly')),
          );
          return;
        }

        setState(() => _isSaving = true);
        try {
          final settings = await ref.read(receiptSettingsProvider.future);
          Supplier? supplierToUse = _selectedSupplier;
          if (_isQuickAddingSupplier) {
            final newSupplier = Supplier(
              name: _newNameController.text,
              phone: _newPhoneController.text,
              location: '',
              notes: 'Quick added during purchase',
              createdAt: DateTime.now(),
            );
            final id = await DatabaseHelper.instance.createSupplier(newSupplier);
            supplierToUse = newSupplier.copyWith(id: id);
            await ref.read(suppliersProvider.notifier).refresh();
          }

          final total = (cratesCount * price) + transport + other;
          final pos = await LocationService.getCurrentLocation();
          
          final effectiveRate = _currencyCode == settings.baseCurrency ? 1.0 : _exchangeRate;
          
          final purchase = Purchase(
            productId: activeProduct?.id ?? 1,
            supplierId: supplierToUse!.id!,
            crates: cratesCount,
            remainingEggs: cratesCount * (activeProduct?.subUnitsPerUnit ?? 30),
            buyingPricePerCrate: price,
            transportCost: transport,
            otherCost: other,
            otherCostDescription: _otherDescriptionController.text.isNotEmpty ? _otherDescriptionController.text : null,
            totalCost: total,
            batchNumber: _batchController.text.isNotEmpty ? _batchController.text : null,
            notes: _notesController.text,
            createdAt: _selectedDate,
            latitude: pos?.latitude ?? 0.0,
            longitude: pos?.longitude ?? 0.0,
            currencyCode: _currencyCode,
            exchangeRate: effectiveRate,
          );

          await DatabaseHelper.instance.createPurchase(purchase);
          ref.read(purchasesProvider.notifier).refresh();
          ref.invalidate(inventoryBalanceProvider);
          ref.invalidate(dashboardSummaryProvider);

          if (!context.mounted) return;
          Navigator.pop(context);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      },
      child: settingsAsync.when(
        data: (settings) => Column(
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
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            suppliersAsync.when(
              data: (list) {
                return Column(
                  children: [
                    DropdownButtonFormField<dynamic>(
                      initialValue: _isQuickAddingSupplier ? 'ADD_NEW' : _selectedSupplier,
                      decoration: const InputDecoration(labelText: 'Supplier *', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
                      items: [
                        ...list.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(color: InstaPalette.textPrimary)))),
                        const DropdownMenuItem(
                          value: 'ADD_NEW',
                          child: Row(children: [Icon(Icons.add, color: InstaPalette.accent), SizedBox(width: 8), Text('Add New Supplier', style: TextStyle(color: InstaPalette.accent, fontWeight: FontWeight.bold))]),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == 'ADD_NEW') {
                          setState(() { _isQuickAddingSupplier = true; _selectedSupplier = null; });
                        } else {
                          setState(() { _isQuickAddingSupplier = false; _selectedSupplier = val as Supplier; });
                        }
                      },
                    ),
                    if (_isQuickAddingSupplier) ...[
                      const SizedBox(height: 16),
                      TextField(controller: _newNameController, decoration: const InputDecoration(labelText: 'New Supplier Name *', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
                      const SizedBox(height: 16),
                      TextField(controller: _newPhoneController, decoration: const InputDecoration(labelText: 'New Supplier Phone', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.phone),
                      const Divider(height: 32),
                    ],
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(color: InstaPalette.accent),
              error: (e, s) => const Text('Error loading suppliers', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCurrencySelector(settings.baseCurrency)),
                if (_currencyCode != settings.baseCurrency)
                  const SizedBox(width: 16),
                if (_currencyCode != settings.baseCurrency)
                  Expanded(
                    child: TextField(
                      controller: _exchangeRateController,
                      decoration: const InputDecoration(labelText: 'Exchange Rate', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => setState(() => _exchangeRate = double.tryParse(v) ?? 1.0),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _cratesController, decoration: InputDecoration(labelText: '${activeProduct?.unitName ?? 'Units'} *', labelStyle: const TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: _priceController, decoration: InputDecoration(labelText: 'Price per ${activeProduct?.unitName ?? 'Unit'} *', labelStyle: const TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batchController,
                    decoration: const InputDecoration(
                      labelText: 'Batch Number',
                      labelStyle: TextStyle(color: InstaPalette.textSecondary),
                      hintText: 'e.g. B-20231027-01',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_fix_high, color: InstaPalette.accent),
                  onPressed: _generateBatchNumber,
                  tooltip: 'Auto-generate Batch ID',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _transportController, decoration: const InputDecoration(labelText: 'Transport Cost', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _otherController, decoration: const InputDecoration(labelText: 'Other Cost', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _otherDescriptionController, decoration: const InputDecoration(labelText: 'Cost Description', labelStyle: TextStyle(color: InstaPalette.textSecondary)))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error loading settings: $e'),
      ),
    );
  }

  Widget _buildCurrencySelector(String baseCurrency) {
    final currencies = ['USD', 'ZiG'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Currency', style: TextStyle(fontSize: 12, color: InstaPalette.textSecondary)),
        DropdownButton<String>(
          value: _currencyCode,
          isExpanded: true,
          items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _currencyCode = v;
                if (v == baseCurrency) {
                  _exchangeRate = 1.0;
                  _exchangeRateController.text = '1.0';
                }
              });
            }
          },
        ),
      ],
    );
  }
}
