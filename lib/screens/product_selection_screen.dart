import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/product.dart';
import '../theme/insta_theme.dart';
import 'main_navigation.dart';

class ProductSelectionScreen extends ConsumerWidget {
  const ProductSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('SELECT BUSINESS LINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: InstaPalette.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: productsAsync.when(
        data: (products) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a product to manage transactions and view insights.',
                textAlign: TextAlign.center,
                style: TextStyle(color: InstaPalette.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: products.length + 1,
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return _buildAddProductCard(context, ref);
                    }
                    final product = products[index];
                    return _buildProductCard(context, ref, product);
                  },
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, Product product) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: InstaPalette.border),
      ),
      child: InkWell(
        onTap: () {
          ref.read(activeProductProvider.notifier).state = product;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: InstaPalette.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(product.name),
                size: 40,
                color: InstaPalette.accent,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              '${product.unitName}${product.subUnitName != null ? '/${product.subUnitName}' : ''}',
              style: const TextStyle(color: InstaPalette.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductCard(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: InstaPalette.border, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () => _showAddProductDialog(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 40, color: InstaPalette.textSecondary),
            SizedBox(height: 8),
            Text(
              'NEW PRODUCT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: InstaPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final subUnitController = TextEditingController();
    final ratioController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name (e.g. Chickens)'),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Primary Unit (e.g. Full Chicken)'),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: subUnitController,
                decoration: const InputDecoration(labelText: 'Sub-unit (Optional, e.g. Piece)'),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: ratioController,
                decoration: const InputDecoration(labelText: 'Sub-units per Unit'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && unitController.text.isNotEmpty) {
                final product = Product(
                  name: nameController.text,
                  unitName: unitController.text,
                  subUnitName: subUnitController.text.isEmpty ? null : subUnitController.text,
                  subUnitsPerUnit: int.tryParse(ratioController.text) ?? 1,
                );
                ref.read(productsProvider.notifier).addProduct(product);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('egg')) return Icons.egg;
    if (n.contains('chicken')) return Icons.pets;
    if (n.contains('feed')) return Icons.grass;
    return Icons.inventory_2;
  }
}
