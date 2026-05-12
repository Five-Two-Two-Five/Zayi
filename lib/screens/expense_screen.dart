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
  String _selectedType = 'Fuel';
  final List<String> _expenseTypes = ['Fuel', 'Repairs', 'Salaries', 'Miscellaneous'];
  bool _isSaving = false;

  void _showAddExpenseDialog() {
    // Start location fetch early
    final locationFuture = LocationService.getCurrentLocation();

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
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  items: _expenseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: _isSaving ? null : (val) => setState(() => _selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Expense Type'),
                ),
                TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number, enabled: !_isSaving),
                TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), enabled: !_isSaving),
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
                final amount = double.tryParse(_amountController.text);
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                  return;
                }
                
                setState(() => _isSaving = true);
                try {
                  // Use pre-fetched location
                  final pos = await locationFuture;
                  final expense = Expense(
                    expenseType: _selectedType,
                    amount: amount,
                    description: _descriptionController.text,
                    createdAt: DateTime.now(),
                    latitude: pos?.latitude ?? 0.0,
                    longitude: pos?.longitude ?? 0.0,
                  );
                  await DatabaseHelper.instance.createExpense(expense);
                  ref.read(expensesProvider.notifier).refresh();
                  ref.invalidate(dashboardSummaryProvider);
                  
                  _amountController.clear();
                  _descriptionController.clear();
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
                      }
                    },
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.money_off)),
                      title: Text('${e.expenseType}: \$${e.amount}'),
                      subtitle: Text('${e.description}\n${DateFormat('yyyy-MM-dd HH:mm').format(e.createdAt)}'),
                      isThreeLine: true,
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
}
