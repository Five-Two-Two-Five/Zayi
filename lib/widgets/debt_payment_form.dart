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
  final _otherMethodController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  final List<String> _methods = ['Cash', 'Card', 'Ecocash', 'Other'];

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
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Payment Amount', prefixIcon: Icon(Icons.attach_money)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _paymentMethod = val!),
              decoration: const InputDecoration(labelText: 'Payment Method'),
            ),
            if (_paymentMethod == 'Other')
              TextField(
                controller: _otherMethodController,
                decoration: const InputDecoration(labelText: 'Specify Method'),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePayment,
                style: ElevatedButton.styleFrom(backgroundColor: InstaPalette.textPrimary, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
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
    final method = _paymentMethod == 'Other' ? _otherMethodController.text : _paymentMethod;
    
    // Apply Payment Method Charges
    final settings = await ref.read(receiptSettingsProvider.future);
    double totalChargeAmount = 0.0;
    String? chargeDescription;
    final charges = settings.paymentMethodCharges.where((c) => c.method == _paymentMethod).toList();
    for (var c in charges) {
      double amt = c.isPercentage ? (amount * (c.value / 100)) : c.value;
      totalChargeAmount += amt;
      chargeDescription = (chargeDescription == null) ? c.description : '$chargeDescription, ${c.description}';
    }

    final updatedSale = widget.sale.copyWith(
      totalRevenue: widget.sale.totalRevenue + totalChargeAmount,
      amountPaid: widget.sale.amountPaid + amount,
      balanceDue: widget.sale.balanceDue + totalChargeAmount - amount,
    );

    await DatabaseHelper.instance.updateSale(updatedSale);
    await DatabaseHelper.instance.addPayment(
      widget.sale.id!, 
      amount, 
      method, 
      _paymentMethod == 'Other' ? _otherMethodController.text : '',
      chargeAmount: totalChargeAmount,
      chargeDescription: chargeDescription,
    ); 
    
    ref.read(salesProvider.notifier).refresh();
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(salePaymentsProvider(widget.sale.id!));
    
    // Generate Payment Receipt
    final customers = await DatabaseHelper.instance.getAllCustomers();
    final customer = customers.firstWhere((c) => c.id == widget.sale.customerId);
    
    final receiptData = {
      'receiptNumber': 'PAY-${widget.sale.id}-${DateTime.now().millisecondsSinceEpoch}',
      'issuer': settings.businessName,
      'address': settings.address,
      'taxId': settings.taxId,
      'phone': settings.phone,
      'customerName': customer.name,
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
      'items': [
        {'name': 'Debt Settlement Payment ($method)', 'qty': 1, 'total': amount.toStringAsFixed(2)},
        if (totalChargeAmount > 0)
          {'name': 'Charge: ${chargeDescription ?? 'Payment Fee'}', 'qty': 1, 'total': totalChargeAmount.toStringAsFixed(2)},
      ],
      'subTotal': (amount + totalChargeAmount).toStringAsFixed(2),
      'total': (amount + totalChargeAmount).toStringAsFixed(2),
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
