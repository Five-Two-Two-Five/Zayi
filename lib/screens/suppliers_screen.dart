import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../widgets/quick_add_dialogs.dart';
import '../theme/insta_theme.dart';

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
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Suppliers', style: TextStyle(color: InstaPalette.textPrimary)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: suppliersAsync.when(
        data: (suppliers) => suppliers.isEmpty
            ? const Center(child: Text('No suppliers found.', style: TextStyle(color: InstaPalette.textSecondary)))
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
                      leading: const CircleAvatar(
                        backgroundColor: InstaPalette.accent,
                        child: Icon(Icons.person, color: InstaPalette.background),
                      ),
                      title: Text(supplier.name, style: const TextStyle(color: InstaPalette.textPrimary)),
                      subtitle: Text(supplier.phone, style: const TextStyle(color: InstaPalette.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: InstaPalette.textSecondary, size: 20),
                            onPressed: () => QuickAddDialogs.showAddSupplierDialog(context, ref, supplier: supplier),
                          ),
                          const Icon(Icons.chevron_right, color: InstaPalette.textSecondary),
                        ],
                      ),
                      onTap: () {
                        // View History logic can be added here
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: InstaPalette.accent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickAddDialogs.showAddSupplierDialog(context, ref),
        backgroundColor: InstaPalette.textPrimary,
        child: const Icon(Icons.add, color: InstaPalette.background),
      ),
    );
  }
}
