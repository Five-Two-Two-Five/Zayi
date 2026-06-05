import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/product.dart';
import '../theme/insta_theme.dart';
import '../database/database_helper.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Manage Products', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        elevation: 0.5,
      ),
      body: productsAsync.when(
        data: (products) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: InstaPalette.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: InstaPalette.accent.withValues(alpha: 0.1),
                  child: Icon(Icons.inventory_2, color: InstaPalette.accent),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Unit: ${p.unitName} | Ratio: ${p.subUnitsPerUnit} ${p.subUnitName ?? ""}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditProductDialog(context, ref, p),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, ref),
        backgroundColor: InstaPalette.textPrimary,
        child: const Icon(Icons.add, color: InstaPalette.background),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    _showProductDialog(context, ref);
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, Product product) {
    _showProductDialog(context, ref, product: product);
  }

  void _showProductDialog(BuildContext context, WidgetRef ref, {Product? product}) {
    final nameController = TextEditingController(text: product?.name);
    final unitController = TextEditingController(text: product?.unitName);
    final subUnitController = TextEditingController(text: product?.subUnitName);
    final ratioController = TextEditingController(text: product?.subUnitsPerUnit.toString() ?? '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Primary Unit')),
              TextField(controller: subUnitController, decoration: const InputDecoration(labelText: 'Sub-unit')),
              TextField(controller: ratioController, decoration: const InputDecoration(labelText: 'Sub-units per Unit'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final p = Product(
                id: product?.id,
                name: nameController.text,
                unitName: unitController.text,
                subUnitName: subUnitController.text.isEmpty ? null : subUnitController.text,
                subUnitsPerUnit: int.tryParse(ratioController.text) ?? 1,
              );
              if (product == null) {
                await DatabaseHelper.instance.createProduct(p);
              } else {
                await DatabaseHelper.instance.updateProduct(p);
              }
              ref.read(productsProvider.notifier).refresh();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: Text(product == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }
}
