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
                        title: Text(
                          '${s.cratesSold} ${activeProduct?.unitName ?? 'Units'} @ ${s.currencyCode} ${s.sellingPricePerCrate}',
                          style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold),
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

    return FullPageAddDialog(
      title: 'New ${activeProduct?.name ?? 'Sale'}',
      isSaving: _isSaving,
      onSave: () async {
        final cratesCount = int.tryParse(_cratesController.text);
        final subUnitsCount = int.tryParse(_subUnitsController.text) ?? 0;
        final price = double.tryParse(_priceController.text);
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

          final baseRevenue = (cratesCount * price) + (subUnitsCount * (price / (activeProduct?.subUnitsPerUnit ?? 30)));
          final taxRate = _selectedTax?['rate'] ?? 0.0;
          final taxLabel = _selectedTax?['label'];
          
          double taxAmount = 0.0;
          double totalRevenue = 0.0;

          if (_isTaxInclusive) {
            totalRevenue = baseRevenue;
            taxAmount = totalRevenue - (totalRevenue / (1 + (taxRate / 100)));
          } else {
            taxAmount = baseRevenue * (taxRate / 100);
            totalRevenue = baseRevenue + taxAmount;
          }

          // Apply Payment Method Charges
          double totalChargeAmount = 0.0;
          String? chargeDescription;
          if (paid > 0) {
            final charges = settings.paymentMethodCharges.where((c) => c.method == _paymentMethod).toList();
            for (var c in charges) {
              double amt = c.isPercentage ? (paid * (c.value / 100)) : c.value;
              totalChargeAmount += amt;
              chargeDescription = (chargeDescription == null) ? c.description : '$chargeDescription, ${c.description}';
            }
          }
          
          totalRevenue += totalChargeAmount;

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
            taxLabel: taxLabel,
            isTaxInclusive: _isTaxInclusive,
            totalRevenue: totalRevenue,
            totalCost: 0,
            profit: 0,
            amountPaid: paid,
            balanceDue: totalRevenue - paid,
            notes: _notesController.text,
            createdAt: _selectedDate,
            latitude: pos?.latitude ?? 0.0,
            longitude: pos?.longitude ?? 0.0,
            currencyCode: _currencyCode,
            exchangeRate: effectiveRate,
          );

          final id = await DatabaseHelper.instance.createSale(sale);
          if (paid > 0) {
            await DatabaseHelper.instance.addPayment(
              id, 
              paid, 
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
            customersAsync.when(
              data: (list) {
                return Column(
                  children: [
                    DropdownButtonFormField<dynamic>(
                      initialValue: _isQuickAddingCustomer ? 'ADD_NEW' : _selectedCustomer,
                      decoration: const InputDecoration(labelText: 'Customer *', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
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
                      TextField(controller: _newNameController, decoration: const InputDecoration(labelText: 'New Customer Name *', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
                      TextField(controller: _newPhoneController, decoration: const InputDecoration(labelText: 'New Customer Phone (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.phone),
                      const Divider(),
                    ],
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(color: InstaPalette.accent),
              error: (e, s) => const Text('Error loading customers', style: TextStyle(color: Colors.red)),
            ),
            Row(
              children: [
                Expanded(child: _buildCurrencySelector(settings.baseCurrency)),
                if (_currencyCode != settings.baseCurrency)
                  const SizedBox(width: 16),
                if (_currencyCode != settings.baseCurrency)
                  Expanded(
                    child: TextField(
                      controller: _exchangeRateController,
                      decoration: const InputDecoration(labelText: 'Exchange Rate *', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => setState(() => _exchangeRate = double.tryParse(v) ?? 1.0),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cratesController, 
                    decoration: InputDecoration(labelText: '${activeProduct?.unitName ?? 'Units'} Sold *', labelStyle: const TextStyle(color: InstaPalette.textSecondary)), 
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                if ((activeProduct?.subUnitsPerUnit ?? 1) > 1) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _subUnitsController,
                      decoration: InputDecoration(labelText: '${activeProduct?.subUnitName ?? 'Sub-units'} Sold', labelStyle: const TextStyle(color: InstaPalette.textSecondary)),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ],
            ),
            TextField(
              controller: _priceController, 
              decoration: InputDecoration(labelText: 'Price per ${activeProduct?.unitName ?? 'Unit'} *', labelStyle: const TextStyle(color: InstaPalette.textSecondary)), 
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() {}),
            ),
            
            // Expected Amount Read-only field
            Builder(
              builder: (context) {
                final crates = double.tryParse(_cratesController.text) ?? 0;
                final subUnits = double.tryParse(_subUnitsController.text) ?? 0;
                final price = double.tryParse(_priceController.text) ?? 0;
                final expected = (crates * price) + (subUnits * (price / (activeProduct?.subUnitsPerUnit ?? 30)));
                return TextField(
                  controller: TextEditingController(text: expected > 0 ? expected.toStringAsFixed(2) : ''),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Expected Amount (Base)',
                    labelStyle: TextStyle(color: InstaPalette.accent),
                    prefixIcon: Icon(Icons.calculate_outlined, color: InstaPalette.accent),
                    filled: true,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            const Text('TAX SETTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
            DropdownButtonFormField<Map<String, dynamic>?>(
              initialValue: _selectedTax,
              decoration: const InputDecoration(labelText: 'Applied Tax', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
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
              controller: _paidController, 
              decoration: const InputDecoration(labelText: 'Amount Paid *', labelStyle: TextStyle(color: InstaPalette.textSecondary)), 
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() {}),
            ),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: ['Cash', 'Card', 'Ecocash', 'Other'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _paymentMethod = val!),
              decoration: const InputDecoration(labelText: 'Payment Method *'),
            ),
            if (_paymentMethod != 'Cash' && paid > 0)
              _buildChargePreview(settings, paid),
            if (_paymentMethod == 'Other')
              TextField(
                controller: _otherMethodController,
                decoration: const InputDecoration(labelText: 'Specify Method *'),
              ),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
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

  Widget _buildCurrencySelector(String baseCurrency) {
    final currencies = ['USD', 'ZiG'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Currency *', style: TextStyle(fontSize: 12, color: InstaPalette.textSecondary)),
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
