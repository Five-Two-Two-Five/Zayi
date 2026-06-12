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
import '../widgets/form_utils.dart';

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
  bool _showAdvanced = false;

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

    final crates = double.tryParse(_cratesController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final transport = double.tryParse(_transportController.text) ?? 0;
    final other = double.tryParse(_otherController.text) ?? 0;
    final total = (crates * price) + transport + other;

    return FullPageAddDialog(
      title: 'New ${activeProduct?.name ?? 'Purchase'}',
      isSaving: _isSaving,
      onSave: () async {
        final cratesCount = int.tryParse(_cratesController.text);
        final priceValue = double.tryParse(_priceController.text);
        final transportValue = double.tryParse(_transportController.text) ?? 0.0;
        final otherValue = double.tryParse(_otherController.text) ?? 0.0;

        if ((!_isQuickAddingSupplier && _selectedSupplier == null) ||
            (_isQuickAddingSupplier && _newNameController.text.isEmpty) ||
            cratesCount == null ||
            priceValue == null) {
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

          final totalCost = (cratesCount * priceValue) + transportValue + otherValue;
          final pos = await LocationService.getCurrentLocation();
          
          final effectiveRate = _currencyCode == settings.baseCurrency ? 1.0 : _exchangeRate;
          
          final purchase = Purchase(
            productId: activeProduct?.id ?? 1,
            supplierId: supplierToUse!.id!,
            crates: cratesCount,
            remainingEggs: cratesCount * (activeProduct?.subUnitsPerUnit ?? 30),
            buyingPricePerCrate: priceValue,
            transportCost: transportValue,
            otherCost: otherValue,
            otherCostDescription: _otherDescriptionController.text.isNotEmpty ? _otherDescriptionController.text : null,
            totalCost: totalCost,
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
            FormSection(
              title: 'Supplier & Date',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                    style: const TextStyle(color: InstaPalette.textPrimary, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: InstaPalette.accent, size: 18),
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
                          decoration: const InputDecoration(labelText: 'Select Supplier *'),
                          items: [
                            ...list.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(color: InstaPalette.textPrimary)))),
                            const DropdownMenuItem(
                              value: 'ADD_NEW',
                              child: Row(children: [Icon(Icons.add, color: InstaPalette.accent, size: 18), SizedBox(width: 8), Text('Add New Supplier', style: TextStyle(color: InstaPalette.accent, fontWeight: FontWeight.bold))]),
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
                          const SizedBox(height: 12),
                          TextField(controller: _newNameController, decoration: const InputDecoration(labelText: 'New Supplier Name *')),
                          const SizedBox(height: 12),
                          TextField(controller: _newPhoneController, decoration: const InputDecoration(labelText: 'New Supplier Phone'), keyboardType: TextInputType.phone),
                        ],
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Error loading suppliers', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            
            FormSection(
              title: 'Purchase Details',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('CURRENCY:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['USD', 'ZiG'].map((c) {
                            final isSelected = _currencyCode == c;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(c, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : InstaPalette.textPrimary)),
                                selected: isSelected,
                                onSelected: (s) {
                                  setState(() {
                                    _currencyCode = c;
                                    if (c == settings.baseCurrency) {
                                      _exchangeRate = 1.0;
                                      _exchangeRateController.text = '1.0';
                                    }
                                  });
                                },
                                selectedColor: InstaPalette.accent,
                                backgroundColor: InstaPalette.background,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : InstaPalette.border)),
                                showCheckmark: false,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_currencyCode != settings.baseCurrency)
                  TextField(
                    controller: _exchangeRateController,
                    decoration: const InputDecoration(labelText: 'Exchange Rate *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() => _exchangeRate = double.tryParse(v) ?? 1.0),
                  ),
                const SizedBox(height: 4),
                FormRow(
                  children: [
                    TextField(
                      controller: _cratesController, 
                      decoration: InputDecoration(labelText: '${activeProduct?.unitName ?? 'Units'} *'), 
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                    TextField(
                      controller: _priceController, 
                      decoration: InputDecoration(labelText: 'Price/${activeProduct?.unitName ?? 'Unit'} *'), 
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                  ],
                ),
              ],
            ),

            FormSection(
              title: 'Additional Costs',
              children: [
                FormRow(
                  children: [
                    TextField(
                      controller: _transportController, 
                      decoration: const InputDecoration(labelText: 'Transport Cost'), 
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                    TextField(
                      controller: _otherController, 
                      decoration: const InputDecoration(labelText: 'Other Costs'), 
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                  ],
                ),
                if (other > 0)
                  TextField(
                    controller: _otherDescriptionController,
                    decoration: const InputDecoration(labelText: 'Cost Description'),
                  ),
              ],
            ),

            // Summary Banner
            if (total > 0)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D7B93).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5D7B93).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Investment:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('$_currencyCode ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D7B93))),
                  ],
                ),
              ),

            // Advanced Toggle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(_showAdvanced ? 'Hide Details' : 'Show More Details (Batch, Notes)'),
                style: TextButton.styleFrom(foregroundColor: InstaPalette.textSecondary, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),

            if (_showAdvanced)
              FormSection(
                title: 'Inventory & Notes',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _batchController,
                          decoration: const InputDecoration(labelText: 'Batch Number', hintText: 'e.g. B-20231027-01'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_fix_high, color: InstaPalette.accent, size: 20),
                        onPressed: _generateBatchNumber,
                        tooltip: 'Auto-generate Batch ID',
                      ),
                    ],
                  ),
                  TextField(
                    controller: _notesController, 
                    decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                    maxLines: 2,
                  ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error loading settings: $e'),
      ),
    );
  }
}
