import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import '../features/receipts/presentation/pages/designer_page.dart';
import '../theme/insta_theme.dart';
import '../widgets/full_page_add_dialog.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  void _showAddExpenseDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseFormPage()));
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Expenses', style: TextStyle(color: InstaPalette.textPrimary)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: expensesAsync.when(
        data: (expenses) => expenses.isEmpty
            ? const Center(child: Text('No expenses recorded.', style: TextStyle(color: InstaPalette.textSecondary)))
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final e = expenses[index];
                  String subtitleText = e.description;
                  if (e.employeeName != null && e.employeeName!.isNotEmpty) {
                    subtitleText = 'Employee: ${e.employeeName}\n$subtitleText';
                  }
                  if (e.extraDetails != null && e.extraDetails!.isNotEmpty) {
                    subtitleText = 'Details: ${e.extraDetails}\n$subtitleText';
                  }

                  return Dismissible(
                    key: Key('expense_${e.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                    await DatabaseHelper.instance.deleteExpense(e.id!);
                    ref.read(expensesProvider.notifier).refresh();
                    ref.invalidate(dashboardSummaryProvider);
                    ref.read(profitTrendProvider.notifier).refresh();
                    ref.read(expenseDistributionProvider.notifier).refresh();
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
                        leading: CircleAvatar(
                          backgroundColor: _getColorForType(e.expenseType),
                          child: const Icon(
                            Icons.money_off,
                            color: InstaPalette.background,
                          ),
                        ),
                        title: Text(
                          '${e.expenseType}: ${e.currencyCode} ${e.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$subtitleText\n${DateFormat('yyyy-MM-dd').format(e.createdAt)}',
                          style: const TextStyle(color: InstaPalette.textSecondary),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.print, color: InstaPalette.accent),
                          onPressed: () async {
                            final settings = await ref.read(receiptSettingsProvider.future);
                            
                            final receiptData = {
                              'receiptNumber': 'EXP-${e.id}',
                              'issuer': settings.businessName,
                              'address': settings.address,
                              'taxId': settings.taxId,
                              'phone': settings.phone,
                              'customerName': e.employeeName ?? 'N/A',
                              'date': DateFormat('yyyy-MM-dd hh:mm a').format(e.createdAt),
                              'items': [
                                {
                                  'name': 'Expense: ${e.expenseType} - ${e.description}',
                                  'qty': 1,
                                  'total': e.amount.toStringAsFixed(2),
                                },
                              ],
                              'subTotal': e.amount.toStringAsFixed(2),
                              'total': e.amount.toStringAsFixed(2),
                              'cash': e.amount.toStringAsFixed(2),
                              'balance': '0.00',
                              'footer': settings.footerNote,
                            };

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
        onPressed: _showAddExpenseDialog,
        backgroundColor: InstaPalette.textPrimary,
        child: const Icon(Icons.add, color: InstaPalette.background),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Delivery':
        return Colors.indigo;
      case 'Employee':
        return Colors.deepPurple;
      default:
        return InstaPalette.accent;
    }
  }
}

class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key});

  @override
  ConsumerState<ExpenseFormPage> createState() => ExpenseFormPageState();
}

class ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _extraDetailsController = TextEditingController();
  final _exchangeRateController = TextEditingController(text: '1.0');
  String _selectedType = 'General';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
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

  final List<String> _expenseTypes = ['General', 'Delivery', 'Employee'];

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(receiptSettingsProvider);

    return FullPageAddDialog(
      title: 'Record Expense',
      isSaving: _isSaving,
      onSave: () async {
        final amt = double.tryParse(_amountController.text);
        if (amt == null) return;

        setState(() => _isSaving = true);
        try {
          final settings = await ref.read(receiptSettingsProvider.future);
          final effectiveRate = _currencyCode == settings.baseCurrency ? 1.0 : _exchangeRate;
          
          final expense = Expense(
            expenseType: _selectedType,
            amount: amt,
            description: _descriptionController.text,
            employeeName: _selectedType == 'Employee' ? _employeeNameController.text : null,
            extraDetails: _selectedType == 'Delivery' ? _extraDetailsController.text : null,
            createdAt: _selectedDate,
            latitude: 0.0,
            longitude: 0.0,
            currencyCode: _currencyCode,
            exchangeRate: effectiveRate,
          );

          await DatabaseHelper.instance.createExpense(expense);
          ref.read(expensesProvider.notifier).refresh();
          ref.invalidate(dashboardSummaryProvider);
          ref.read(profitTrendProvider.notifier).refresh();
          ref.read(expenseDistributionProvider.notifier).refresh();

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
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Expense Type *', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
              items: _expenseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: InstaPalette.textPrimary)))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),
            if (_selectedType == 'Employee') ...[
              TextField(controller: _employeeNameController, decoration: const InputDecoration(labelText: 'Employee Name *', labelStyle: TextStyle(color: InstaPalette.textSecondary)), enabled: !_isSaving),
              const SizedBox(height: 16),
            ],
            if (_selectedType == 'Delivery') ...[
              TextField(controller: _extraDetailsController, decoration: const InputDecoration(labelText: 'Vehicle / Route Details *', labelStyle: TextStyle(color: InstaPalette.textSecondary)), enabled: !_isSaving),
              const SizedBox(height: 16),
            ],
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
            const SizedBox(height: 16),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount *', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number, enabled: !_isSaving),
            const SizedBox(height: 16),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary)), enabled: !_isSaving),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
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
