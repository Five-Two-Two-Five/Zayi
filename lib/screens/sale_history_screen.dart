import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';
import '../theme/insta_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaleHistoryScreen extends ConsumerStatefulWidget {
  final Sale sale;
  final Customer customer;

  const SaleHistoryScreen({super.key, required this.sale, required this.customer});

  @override
  ConsumerState<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends ConsumerState<SaleHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = DatabaseHelper.instance.getPaymentsForSale(widget.sale.id!);
  }
// ... rest of the file
  @override
  Widget build(BuildContext context) {
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
          const Text('PAYMENT HISTORY', style: TextStyle(fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _paymentsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final payments = snapshot.data!;
              if (payments.isEmpty) return const Text('No payments recorded.');
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  return Card(
                    color: InstaPalette.cardBackground,
                    child: ListTile(
                      title: Text('Payment: \$${(p['amount'] as num).toStringAsFixed(2)}'),
                      subtitle: Text(DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(p['created_at']))),
                      leading: const Icon(Icons.payment, color: InstaPalette.accent),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaleSummary() {
    return Card(
      color: InstaPalette.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(title: const Text('Original Sale'), trailing: Text('\$${widget.sale.totalRevenue.toStringAsFixed(2)}')),
            ListTile(title: const Text('Total Paid'), trailing: Text('\$${widget.sale.amountPaid.toStringAsFixed(2)}')),
            ListTile(title: const Text('Balance Due'), trailing: Text('\$${widget.sale.balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
