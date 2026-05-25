import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../widgets/quick_add_dialogs.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: suppliersAsync.when(
        data: (suppliers) => suppliers.isEmpty
            ? const Center(child: Text('No suppliers found.'))
            : ListView.builder(
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  return Dismissible(
                    key: Key('supplier_${supplier.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await DatabaseHelper.instance.deleteSupplier(
                        supplier.id!,
                      );
                      ref.read(suppliersProvider.notifier).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Supplier deleted')),
                        );
                      }
                    },
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(supplier.name),
                      subtitle: Text(supplier.phone),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // View History logic can be added here
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickAddDialogs.showAddSupplierDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
