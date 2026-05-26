// lib/features/receipts/services/receipt_mapper.dart
import '../../../../models/sale.dart';
import '../../../../models/customer.dart';
import '../../../../models/purchase.dart';
import '../../../../models/supplier.dart';
import 'package:intl/intl.dart';

class ReceiptMapper {
  static Map<String, dynamic> fromSale(Sale sale, Customer customer) {
    return {
      'receiptNumber': '1-${sale.id}',
      'issuer': 'Zayi Enterprise',
      'customerName': customer.name,
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(sale.createdAt),
      'items': [
        {
          'name': 'Sale Item',
          'qty': sale.cratesSold,
          'total': sale.totalRevenue.toStringAsFixed(2),
        },
      ],
      'subTotal': sale.totalRevenue.toStringAsFixed(2),
      'total': sale.totalRevenue.toStringAsFixed(2),
      'cash': sale.amountPaid.toStringAsFixed(2),
      'balance': sale.balanceDue.toStringAsFixed(2),
    };
  }

  static Map<String, dynamic> fromPurchase(Purchase purchase, Supplier supplier) {
    return {
      'receiptNumber': 'P-${purchase.id}',
      'issuer': supplier.name, // The supplier is the issuer here
      'customerName': 'Zayi Enterprise', // Zayi is the receiver/customer
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(purchase.createdAt),
      'items': [
        {
          'name': 'Purchase Item',
          'qty': purchase.crates,
          'total': purchase.totalCost.toStringAsFixed(2),
        },
      ],
      'subTotal': purchase.totalCost.toStringAsFixed(2),
      'total': purchase.totalCost.toStringAsFixed(2),
      'cash': purchase.totalCost.toStringAsFixed(2),
      'balance': '0.00',
    };
  }
}
