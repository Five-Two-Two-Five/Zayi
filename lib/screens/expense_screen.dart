import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _extraDetailsController = TextEditingController();
  String _selectedType = 'General';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _expenseTypes = ['General', 'Delivery', 'Employee'];

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
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
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Expense Type'),
                  items: _expenseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                if (_selectedType == 'Employee')
                  TextField(
                    controller: _employeeNameController,
                    decoration: const InputDecoration(labelText: 'Employee Name'),
                    enabled: !_isSaving,
                  ),
                if (_selectedType == 'Delivery')
                  TextField(
                    controller: _extraDetailsController,
                    decoration: const InputDecoration(labelText: 'Vehicle / Route Details'),
                    enabled: !_isSaving,
                  ),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  enabled: !_isSaving,
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  enabled: !_isSaving,
                ),
                if (_isSaving) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _isSaving ? null : () async {
                final amt = double.tryParse(_amountController.text);
                if (amt == null) return;

                setState(() => _isSaving = true);
                try {
                  final expense = Expense(
                    expenseType: _selectedType,
                    amount: amt,
                    description: _descriptionController.text,
                    employeeName: _selectedType == 'Employee' ? _employeeNameController.text : null,
                    extraDetails: _selectedType == 'Delivery' ? _extraDetailsController.text : null,
                    createdAt: _selectedDate,
                    latitude: 0.0,
                    longitude: 0.0,
                  );

                  await DatabaseHelper.instance.createExpense(expense);
                  ref.read(expensesProvider.notifier).refresh();
                  ref.invalidate(dashboardSummaryProvider);

                  _amountController.clear();
                  _descriptionController.clear();
                  _employeeNameController.clear();
                  _extraDetailsController.clear();
                  _selectedDate = DateTime.now();

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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: expensesAsync.when(
        data: (expenses) => expenses.isEmpty
            ? const Center(child: Text('No expenses recorded.'))
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
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForType(e.expenseType),
                          child: const Icon(Icons.money_off, color: Colors.white),
                        ),
                        title: Text('${e.expenseType}: \$${e.amount.toStringAsFixed(2)}'),
                        subtitle: Text('$subtitleText\n${DateFormat('yyyy-MM-dd').format(e.createdAt)}'),
                        isThreeLine: true,
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Delivery': return Colors.indigo;
      case 'Employee': return Colors.deepPurple;
      default: return Colors.red;
    }
  }
}
