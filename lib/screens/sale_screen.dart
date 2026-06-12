import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../models/receipt_settings.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';
import '../features/receipts/services/receipt_mapper.dart';
import '../features/receipts/presentation/pages/designer_page.dart';
import 'sale_history_screen.dart';
import '../theme/insta_theme.dart';
import '../widgets/full_page_add_dialog.dart';
import '../widgets/debt_payment_form.dart';
import '../widgets/form_utils.dart';

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
    showDialog(
      context: context,
      builder: (context) => DebtPaymentForm(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final activeProduct = ref.watch(activeProductProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      body: salesAsync.when(
        data: (sales) => sales.isEmpty
            ? const Center(child: Text('No sales recorded.', style: TextStyle(color: InstaPalette.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final s = sales[index];
                  return Dismissible(
                    key: Key('sale_${s.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text('Are you sure you want to delete this sale? This action cannot be undone and will adjust inventory.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel', style: TextStyle(color: InstaPalette.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFFC05656)), // Matte Red
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    background: Container(
                      color: const Color(0xFFC05656), // Matte Red
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
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
                      elevation: 0,
                      child: ListTile(
                        onTap: () {
                          final customer = ref.read(customersProvider).when(
                            data: (list) => list.firstWhere((c) => c.id == s.customerId, orElse: () => Customer(id: s.customerId, name: 'Unknown', phone: '', location: '', notes: '', createdAt: DateTime.now())),
                            error: (err, stack) => Customer(id: s.customerId, name: 'Unknown', phone: '', location: '', notes: '', createdAt: DateTime.now()),
                            loading: () => Customer(id: s.customerId, name: 'Unknown', phone: '', location: '', notes: '', createdAt: DateTime.now()),
                          );
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SaleHistoryScreen(sale: s, customer: customer)));
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${s.cratesSold} ${activeProduct?.unitName ?? 'Units'} @ ${s.currencyCode} ${s.sellingPricePerCrate}',
                                style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: s.balanceDue <= 0 
                                    ? const Color(0xFF6B8E6B).withValues(alpha: 0.1) // Matte Green
                                    : const Color(0xFFBC8F4F).withValues(alpha: 0.1), // Matte Amber
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: s.balanceDue <= 0 ? const Color(0xFF6B8E6B) : const Color(0xFFBC8F4F),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                s.balanceDue <= 0 ? 'PAID' : 'DEBT',
                                style: TextStyle(
                                  color: s.balanceDue <= 0 ? const Color(0xFF6B8E6B) : const Color(0xFFBC8F4F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Revenue: ${s.currencyCode} ${s.totalRevenue.toStringAsFixed(2)}\nDue: ${s.currencyCode} ${s.balanceDue.toStringAsFixed(2)}',
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
  final _subUnitsController = TextEditingController(text: '0');
  final _priceController = TextEditingController();
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();
  final _exchangeRateController = TextEditingController(text: '1.0');

  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isQuickAddingCustomer = false;
  String _currencyCode = 'USD';
  double _exchangeRate = 1.0;
  String _paymentMethod = 'Cash';

  bool _showAdvanced = false;
  Map<String, dynamic>? _selectedTax;
  bool _isTaxInclusive = false;
  final _otherMethodController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final settingsAsync = ref.watch(receiptSettingsProvider);
    final activeProduct = ref.watch(activeProductProvider);

    final paid = double.tryParse(_paidController.text.isEmpty ? '0' : _paidController.text) ?? 0.0;
    final crates = double.tryParse(_cratesController.text) ?? 0;
    final subUnits = double.tryParse(_subUnitsController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    
    final baseRevenue = (crates * price) + (subUnits * (price / (activeProduct?.subUnitsPerUnit ?? 30)));
    final taxRate = _selectedTax?['rate'] ?? 0.0;
    double taxAmount = 0.0;
    double totalRevenue = 0.0;

    if (_isTaxInclusive) {
      totalRevenue = baseRevenue;
      taxAmount = totalRevenue - (totalRevenue / (1 + (taxRate / 100)));
    } else {
      taxAmount = baseRevenue * (taxRate / 100);
      totalRevenue = baseRevenue + taxAmount;
    }

    return FullPageAddDialog(
      title: 'New ${activeProduct?.name ?? 'Sale'}',
      isSaving: _isSaving,
      onSave: () async {
        final cratesCount = int.tryParse(_cratesController.text);
        final subUnitsCount = int.tryParse(_subUnitsController.text) ?? 0;
        final price = double.tryParse(_priceController.text);
        final paidValue = double.tryParse(_paidController.text.isEmpty ? '0' : _paidController.text) ?? 0.0;

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
          final settings = await ref.read(receiptSettingsProvider.future);
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

          // Apply Payment Method Charges
          double totalChargeAmount = 0.0;
          String? chargeDescription;
          if (paidValue > 0) {
            final charges = settings.paymentMethodCharges.where((c) => c.method == _paymentMethod).toList();
            for (var c in charges) {
              double amt = c.isPercentage ? (paidValue * (c.value / 100)) : c.value;
              totalChargeAmount += amt;
              chargeDescription = (chargeDescription == null) ? c.description : '$chargeDescription, ${c.description}';
            }
          }
          
          final finalRevenue = totalRevenue + totalChargeAmount;

          final pos = await LocationService.getCurrentLocation();
          final effectiveRate = _currencyCode == settings.baseCurrency ? 1.0 : _exchangeRate;

          final sale = Sale(
            productId: activeProduct?.id ?? 1,
            customerId: customerToUse!.id!,
            cratesSold: cratesCount,
            eggsSold: subUnitsCount,
            sellingPricePerCrate: price,
            deliveryCost: 0,
            employeeCost: 0,
            taxRate: taxRate,
            taxAmount: taxAmount,
            taxLabel: _selectedTax?['label'],
            isTaxInclusive: _isTaxInclusive,
            totalRevenue: finalRevenue,
            totalCost: 0,
            profit: 0,
            amountPaid: paidValue,
            balanceDue: finalRevenue - paidValue,
            notes: _notesController.text,
            createdAt: _selectedDate,
            latitude: pos?.latitude ?? 0.0,
            longitude: pos?.longitude ?? 0.0,
            currencyCode: _currencyCode,
            exchangeRate: effectiveRate,
          );

          final id = await DatabaseHelper.instance.createSale(sale);
          if (paidValue > 0) {
            await DatabaseHelper.instance.addPayment(
              id, 
              paidValue, 
              _paymentMethod == 'Other' ? _otherMethodController.text : _paymentMethod, 
              '',
              chargeAmount: totalChargeAmount,
              chargeDescription: chargeDescription,
            );
          }

          ref.read(salesProvider.notifier).refresh();
          ref.invalidate(inventoryBalanceProvider);
          ref.invalidate(dashboardSummaryProvider);
          ref.read(profitTrendProvider.notifier).refresh();

          if (!context.mounted) return;
          Navigator.pop(context);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      },
      child: settingsAsync.when(
        data: (settings) => Column(
          children: [
            FormSection(
              title: 'Customer & Date',
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
                customersAsync.when(
                  data: (list) {
                    return Column(
                      children: [
                        DropdownButtonFormField<dynamic>(
                          initialValue: _isQuickAddingCustomer ? 'ADD_NEW' : _selectedCustomer,
                          decoration: const InputDecoration(labelText: 'Select Customer *'),
                          items: [
                            ...list.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(color: InstaPalette.textPrimary)))),
                            const DropdownMenuItem(
                              value: 'ADD_NEW',
                              child: Row(children: [Icon(Icons.add, color: InstaPalette.accent, size: 18), SizedBox(width: 8), Text('Add New Customer', style: TextStyle(color: InstaPalette.accent, fontWeight: FontWeight.bold))]),
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
                          const SizedBox(height: 12),
                          TextField(controller: _newNameController, decoration: const InputDecoration(labelText: 'New Customer Name *')),
                          const SizedBox(height: 12),
                          TextField(controller: _newPhoneController, decoration: const InputDecoration(labelText: 'New Customer Phone (Optional)'), keyboardType: TextInputType.phone),
                        ],
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Error loading customers', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            
            FormSection(
              title: 'Transaction Details',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    if ((activeProduct?.subUnitsPerUnit ?? 1) > 1)
                      TextField(
                        controller: _subUnitsController,
                        decoration: InputDecoration(labelText: activeProduct?.subUnitName ?? 'Sub-units'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                      ),
                  ],
                ),
                TextField(
                  controller: _priceController, 
                  decoration: InputDecoration(labelText: 'Price per ${activeProduct?.unitName ?? 'Unit'} *'), 
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
              ],
            ),

            FormSection(
              title: 'Payment',
              children: [
                TextField(
                  controller: _paidController, 
                  decoration: const InputDecoration(labelText: 'Amount Paid *'), 
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 4),
                const Text('PAYMENT METHOD:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Cash', 'Card', 'Ecocash', 'Other'].map((m) {
                      final isSelected = _paymentMethod == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(m, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : InstaPalette.textPrimary)),
                          selected: isSelected,
                          onSelected: (s) => setState(() => _paymentMethod = m),
                          selectedColor: InstaPalette.accent,
                          backgroundColor: InstaPalette.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : InstaPalette.border)),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_paymentMethod != 'Cash' && paid > 0)
                  _buildChargePreview(settings, paid),
                if (_paymentMethod == 'Other')
                  TextField(
                    controller: _otherMethodController,
                    decoration: const InputDecoration(labelText: 'Specify Method *'),
                  ),
              ],
            ),

            // Summary Banner
            if (baseRevenue > 0)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D7B93).withValues(alpha: 0.1), // Matte Blue Tint
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5D7B93).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transaction Total:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('$_currencyCode ${totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D7B93))),
                      ],
                    ),
                    if (taxAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Incl. ${_selectedTax?['label']} (${_selectedTax?['rate']}%):', style: const TextStyle(fontSize: 11, color: InstaPalette.textSecondary)),
                            Text('$_currencyCode ${taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: InstaPalette.textSecondary)),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance Due:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(
                          '$_currencyCode ${(totalRevenue - paid).toStringAsFixed(2)}', 
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: (totalRevenue - paid) > 0 ? const Color(0xFFBC8F4F) : const Color(0xFF6B8E6B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Advanced Toggle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(_showAdvanced ? 'Hide Advanced Settings' : 'Show Advanced Settings (Tax, Notes)'),
                style: TextButton.styleFrom(foregroundColor: InstaPalette.textSecondary, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),

            if (_showAdvanced)
              FormSection(
                title: 'Advanced Settings',
                children: [
                  DropdownButtonFormField<Map<String, dynamic>?>(
                    initialValue: _selectedTax,
                    decoration: const InputDecoration(labelText: 'Applied Tax'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Tax (0%)')),
                      ...settings.predefinedTaxes.map((tax) => DropdownMenuItem(
                        value: tax,
                        child: Text('${tax['label']} (${tax['rate']}%)'),
                      )),
                    ],
                    onChanged: (val) => setState(() => _selectedTax = val),
                  ),
                  if (_selectedTax != null)
                    SwitchListTile(
                      title: const Text('Tax is Inclusive', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Amount already includes tax', style: TextStyle(fontSize: 11)),
                      value: _isTaxInclusive,
                      onChanged: (v) => setState(() => _isTaxInclusive = v),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: InstaPalette.accent,
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

  Widget _buildChargePreview(ReceiptSettings settings, double paid) {
    final charges = settings.paymentMethodCharges.where((c) => c.method == _paymentMethod).toList();
    if (charges.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Applied Charges', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 4),
          ...charges.map((c) {
            double amt = c.isPercentage ? (paid * (c.value / 100)) : c.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.description, style: const TextStyle(fontSize: 11)),
                  Text('+\$${amt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
