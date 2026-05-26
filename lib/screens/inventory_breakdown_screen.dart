import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/insta_theme.dart';
import '../models/purchase.dart';

class InventoryBreakdownScreen extends ConsumerWidget {
  const InventoryBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(inventoryBreakdownProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Inventory Breakdown', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: breakdownAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No stock currently available.', style: TextStyle(color: InstaPalette.textSecondary)),
            );
          }

          double totalValue = 0;
          int totalCrates = 0;
          int totalRemainingEggs = 0;

          for (var item in items) {
            final purchase = Purchase.fromMap(item);
            totalValue += purchase.remainingEggs * purchase.pricePerEgg;
            totalRemainingEggs += purchase.remainingEggs;
          }
          totalCrates = totalRemainingEggs ~/ 30;
          int leftoverEggs = totalRemainingEggs % 30;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: InstaPalette.cardBackground,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Total Value', '\$${totalValue.toStringAsFixed(2)}'),
                    _buildStat('Total Stock', '$totalCrates Crates${leftoverEggs > 0 ? ' $leftoverEggs Eggs' : ''}'),
                  ],
                ),
              ),
              const Divider(height: 1, color: InstaPalette.border),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final purchase = Purchase.fromMap(item);
                    final supplierName = item['supplier_name'] ?? 'Unknown Supplier';
                    final date = DateFormat('MMM dd, yyyy').format(purchase.createdAt);
                    
                    final crates = purchase.remainingEggs ~/ 30;
                    final eggs = purchase.remainingEggs % 30;
                    final value = purchase.remainingEggs * purchase.pricePerEgg;

                    return Card(
                      elevation: 0,
                      color: InstaPalette.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: InstaPalette.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(supplierName, style: const TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
                            Text('\$${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Purchased on $date', style: const TextStyle(fontSize: 12, color: InstaPalette.textSecondary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildBadge('$crates Crates', Colors.blue),
                                if (eggs > 0) ...[
                                  const SizedBox(width: 8),
                                  _buildBadge('$eggs Eggs', Colors.orange),
                                ],
                                const Spacer(),
                                Text('@ \$${(purchase.pricePerEgg * 30).toStringAsFixed(2)}/Crate', style: const TextStyle(fontSize: 11, color: InstaPalette.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: InstaPalette.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
