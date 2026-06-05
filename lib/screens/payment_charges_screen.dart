import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/payment_method_charge.dart';
import '../models/receipt_settings.dart';
import '../theme/insta_theme.dart';

class PaymentChargesForm extends ConsumerStatefulWidget {
  const PaymentChargesForm({super.key});

  @override
  ConsumerState<PaymentChargesForm> createState() => _PaymentChargesFormState();
}

class _PaymentChargesFormState extends ConsumerState<PaymentChargesForm> {
  final List<String> _methods = ['Cash', 'Card', 'Ecocash', 'Other'];
  List<PaymentMethodCharge> _charges = [];
  bool _isInitialized = false;

  void _initCharges(ReceiptSettings settings) {
    if (_isInitialized) return;
    _charges = List<PaymentMethodCharge>.from(settings.paymentMethodCharges);
    _isInitialized = true;
  }

  Future<void> _saveCharges() async {
    final settingsAsync = ref.read(receiptSettingsProvider);
    if (settingsAsync is AsyncData<ReceiptSettings>) {
      final updatedSettings = settingsAsync.value.copyWith(
        paymentMethodCharges: _charges,
      );
      await ref.read(receiptSettingsProvider.notifier).updateSettings(updatedSettings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment charges saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(receiptSettingsProvider);

    return settingsAsync.when(
        data: (settings) {
          _initCharges(settings);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _charges.length,
                  itemBuilder: (context, index) {
                    final charge = _charges[index];
                    return _buildChargeCard(index, charge);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _charges.add(PaymentMethodCharge(
                          method: _methods[0],
                          description: '',
                          isPercentage: true,
                          value: 0.0,
                        ));
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('ADD NEW CHARGE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: InstaPalette.textPrimary,
                      foregroundColor: InstaPalette.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveCharges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: InstaPalette.textPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('SAVE CHARGES'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: InstaPalette.accent)),
        error: (e, s) => Center(child: Text('Error: $e')),
      );
  }

  Widget _buildChargeCard(int index, PaymentMethodCharge charge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: InstaPalette.border),
      ),
      elevation: 0,
      color: InstaPalette.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _methods.contains(charge.method) ? charge.method : 'Other',
                    items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _charges[index] = charge.copyWith(method: val!);
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Payment Method', isDense: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _charges.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: charge.description,
              onChanged: (val) {
                _charges[index] = charge.copyWith(description: val);
              },
              decoration: const InputDecoration(labelText: 'Description (e.g. Transaction Fee)', isDense: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<bool>(
                    initialValue: charge.isPercentage,
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Percentage (%)')),
                      DropdownMenuItem(value: false, child: Text('Constant Amount')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _charges[index] = charge.copyWith(isPercentage: val!);
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Charge Type', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: charge.value.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      _charges[index] = charge.copyWith(value: double.tryParse(val) ?? 0.0);
                    },
                    decoration: const InputDecoration(labelText: 'Value', isDense: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
