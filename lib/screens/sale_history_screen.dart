import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../theme/insta_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/debt_payment_form.dart';
import '../providers/providers.dart';

class SaleHistoryScreen extends ConsumerStatefulWidget {
  final Sale sale;
  final Customer customer;

  const SaleHistoryScreen({super.key, required this.sale, required this.customer});

  @override
  ConsumerState<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends ConsumerState<SaleHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(salePaymentsProvider(widget.sale.id!));

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: Text('Sale #${widget.sale.id} History', style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSaleSummary(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PAYMENT HISTORY', style: TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
              if (widget.sale.balanceDue > 0)
                ElevatedButton(
                  onPressed: () => showDialog(context: context, builder: (_) => DebtPaymentForm(sale: widget.sale)),
                  style: ElevatedButton.styleFrom(backgroundColor: InstaPalette.accent),
                  child: const Text('Add Payment', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          paymentsAsync.when(
            data: (payments) {
              if (payments.isEmpty) return const Text('No payments recorded.');
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final amount = (p['amount'] as num).toDouble();
                  final chargeAmt = (p['charge_amount'] as num?)?.toDouble() ?? 0.0;
                  final chargeDesc = p['charge_description'] as String?;

                  return Card(
                    elevation: 0,
                    color: InstaPalette.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: InstaPalette.border),
                    ),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment: ${widget.sale.currencyCode} ${amount.toStringAsFixed(2)}'),
                          if (chargeAmt > 0)
                            Text(
                              '+ ${widget.sale.currencyCode} ${chargeAmt.toStringAsFixed(2)} (Fee)',
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(p['created_at']))),
                          if (chargeAmt > 0 && chargeDesc != null && chargeDesc.isNotEmpty)
                            Text(
                              chargeDesc,
                              style: const TextStyle(color: InstaPalette.textSecondary, fontSize: 11),
                            ),
                        ],
                      ),
                      leading: const Icon(Icons.payment, color: InstaPalette.accent),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleSummary() {
    return Card(
      elevation: 0,
      color: InstaPalette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: InstaPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(title: const Text('Original Sale'), trailing: Text('${widget.sale.currencyCode} ${widget.sale.totalRevenue.toStringAsFixed(2)}')),
            ListTile(title: const Text('Total Paid'), trailing: Text('${widget.sale.currencyCode} ${widget.sale.amountPaid.toStringAsFixed(2)}')),
            ListTile(title: const Text('Balance Due'), trailing: Text('${widget.sale.currencyCode} ${widget.sale.balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
