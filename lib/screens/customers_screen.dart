import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../widgets/quick_add_dialogs.dart';
import '../theme/insta_theme.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Customers', style: TextStyle(color: InstaPalette.textPrimary)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: customersAsync.when(
        data: (customers) => customers.isEmpty
            ? const Center(child: Text('No customers found.', style: TextStyle(color: InstaPalette.textSecondary)))
            : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Dismissible(
                    key: Key('customer_${customer.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red, // Keep red for delete
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await DatabaseHelper.instance.deleteCustomer(
                        customer.id!,
                      );
                      ref.read(customersProvider.notifier).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Customer deleted')),
                        );
                      }
                    },
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: InstaPalette.accent,
                        child: Icon(Icons.person, color: InstaPalette.background),
                      ),
                      title: Text(customer.name, style: const TextStyle(color: InstaPalette.textPrimary)),
                      subtitle: Text(customer.phone, style: const TextStyle(color: InstaPalette.textSecondary)),
                      trailing: const Icon(Icons.chevron_right, color: InstaPalette.textSecondary),
                      onTap: () {
                        // View History logic
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: InstaPalette.accent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickAddDialogs.showAddCustomerDialog(context, ref),
        backgroundColor: InstaPalette.textPrimary,
        child: const Icon(Icons.add, color: InstaPalette.background),
      ),
    );
  }
}
