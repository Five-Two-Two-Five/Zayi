import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/fixed_asset.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../theme/insta_theme.dart';
import '../widgets/full_page_add_dialog.dart';

class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  void _showAddAssetDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const _AssetFormPage()));
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Fixed Assets', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: assetsAsync.when(
        data: (assets) => assets.isEmpty
            ? const Center(child: Text('No assets recorded.', style: TextStyle(color: InstaPalette.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  final purchaseDate = DateFormat('MMM dd, yyyy').format(asset.purchaseDate);
                  
                  return Card(
                    color: InstaPalette.cardBackground,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(asset.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
                              Text('\$${asset.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Purchased on $purchaseDate', style: const TextStyle(fontSize: 12, color: InstaPalette.textSecondary)),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStat('Book Value', '\$${asset.bookValue.toStringAsFixed(2)}'),
                              _buildStat('Accum. Depr.', '\$${asset.accumulatedDepreciation.toStringAsFixed(2)}'),
                              _buildStat('Monthly Depr.', '\$${asset.monthlyDepreciation.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: InstaPalette.textSecondary),
                              const SizedBox(width: 4),
                              Text('Useful Life: ${asset.usefulLifeMonths} months', style: const TextStyle(fontSize: 11, color: InstaPalette.textSecondary)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Asset?'),
                                      content: const Text('This action cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await DatabaseHelper.instance.deleteFixedAsset(asset.id!);
                                    ref.read(assetsProvider.notifier).refresh();
                                    ref.invalidate(dashboardSummaryProvider);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: InstaPalette.accent)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        backgroundColor: InstaPalette.textPrimary,
        child: const Icon(Icons.add, color: InstaPalette.background),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: InstaPalette.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: InstaPalette.textPrimary)),
      ],
    );
  }
}

class _AssetFormPage extends StatefulWidget {
  const _AssetFormPage();

  @override
  State<_AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<_AssetFormPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _lifeController = TextEditingController(text: '60'); // Default 5 years
  final _residualController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return FullPageAddDialog(
          title: 'Add Fixed Asset',
          isSaving: _isSaving,
          onSave: () async {
            if (_nameController.text.isEmpty || _priceController.text.isEmpty || _lifeController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
              return;
            }

            setState(() => _isSaving = true);
            try {
              final asset = FixedAsset(
                name: _nameController.text,
                purchasePrice: double.parse(_priceController.text),
                purchaseDate: _selectedDate,
                usefulLifeMonths: int.parse(_lifeController.text),
                residualValue: double.parse(_residualController.text),
                notes: _notesController.text,
              );

              await DatabaseHelper.instance.createFixedAsset(asset.toMap());
              ref.read(assetsProvider.notifier).refresh();
              ref.invalidate(dashboardSummaryProvider);
              if (!mounted) return;
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            } finally {
              if (mounted) setState(() => _isSaving = false);
            }
          },
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Asset Name (e.g. Delivery Van)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Purchase Price', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
              ListTile(
                title: Text('Purchase Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}', style: const TextStyle(color: InstaPalette.textPrimary)),
                trailing: const Icon(Icons.calendar_today, color: InstaPalette.textPrimary),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              TextField(controller: _lifeController, decoration: const InputDecoration(labelText: 'Useful Life (Months)', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
              TextField(controller: _residualController, decoration: const InputDecoration(labelText: 'Residual Value (Scrap Value)', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
              TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
            ],
          ),
        );
      },
    );
  }
}
