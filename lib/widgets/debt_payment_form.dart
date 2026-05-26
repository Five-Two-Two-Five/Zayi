import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../features/receipts/presentation/pages/designer_page.dart';
import '../theme/insta_theme.dart';
import 'package:intl/intl.dart';

class DebtPaymentForm extends ConsumerStatefulWidget {
  final Sale sale;

  const DebtPaymentForm({super.key, required this.sale});

  @override
  ConsumerState<DebtPaymentForm> createState() => _DebtPaymentFormState();
}

class _DebtPaymentFormState extends ConsumerState<DebtPaymentForm> {
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Settle Debt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining Balance', style: TextStyle(color: InstaPalette.textSecondary)),
                  Text('\$${widget.sale.balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePayment,
                style: ElevatedButton.styleFrom(backgroundColor: InstaPalette.textPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('RECORD PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > widget.sale.balanceDue) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    setState(() => _isSaving = true);
    
    // Create an "Equity-like" transaction or just update the sale? 
    // To generate a receipt, we need a data representation.
    // Let's update the sale and create a Payment object.
    
    final updatedSale = widget.sale.copyWith(
      amountPaid: widget.sale.amountPaid + amount,
      balanceDue: widget.sale.balanceDue - amount,
    );

    await DatabaseHelper.instance.updateSale(updatedSale);
    await DatabaseHelper.instance.addPayment(widget.sale.id!, amount); // Persist record
    
    ref.read(salesProvider.notifier).refresh();
    ref.invalidate(dashboardSummaryProvider);
    
    // Generate Payment Receipt
    final customers = await DatabaseHelper.instance.getAllCustomers();
    final customer = customers.firstWhere((c) => c.id == widget.sale.customerId);
    final settings = await ref.read(receiptSettingsProvider.future);
    
    final receiptData = {
      'receiptNumber': 'PAY-${widget.sale.id}-${DateTime.now().millisecondsSinceEpoch}',
      'issuer': settings.businessName,
      'address': settings.address,
      'taxId': settings.taxId,
      'phone': settings.phone,
      'customerName': customer.name,
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
      'items': [
        {'name': 'Debt Settlement Payment', 'qty': 1, 'total': amount.toStringAsFixed(2)},
      ],
      'subTotal': amount.toStringAsFixed(2),
      'total': amount.toStringAsFixed(2),
      'cash': amount.toStringAsFixed(2),
      'balance': updatedSale.balanceDue.toStringAsFixed(2),
      'footer': settings.footerNote,
    };

    if (!mounted) return;
    Navigator.pop(context); // Close dialog
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DesignerPage(transactionData: receiptData, isReadOnly: true)),
    );
  }
}
