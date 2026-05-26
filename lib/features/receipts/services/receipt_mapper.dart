// lib/features/receipts/services/receipt_mapper.dart
import '../../../../models/sale.dart';
import '../../../../models/customer.dart';
import '../../../../models/purchase.dart';
import '../../../../models/supplier.dart';
import '../../../../models/receipt_settings.dart';
import 'package:intl/intl.dart';

class ReceiptMapper {
  static Map<String, dynamic> fromSale(Sale sale, Customer customer, {ReceiptSettings? settings}) {
    final businessName = settings?.businessName ?? 'Zayi Enterprise';
    final address = settings?.address ?? '';
    final taxId = settings?.taxId ?? '';
    final phone = settings?.phone ?? '';

    return {
      'receiptNumber': '1-${sale.id}',
      'issuer': businessName,
      'address': address,
      'taxId': taxId,
      'phone': phone,
      'customerName': customer.name,
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(sale.createdAt),
      'items': [
        {
          'name': 'Sale Item',
          'qty': sale.cratesSold,
          'total': (sale.totalRevenue - sale.taxAmount).toStringAsFixed(2),
        },
      ],
      'tax': sale.taxAmount.toStringAsFixed(2),
      'subTotal': (sale.totalRevenue - sale.taxAmount).toStringAsFixed(2),
      'total': sale.totalRevenue.toStringAsFixed(2),
      'cash': sale.amountPaid.toStringAsFixed(2),
      'balance': sale.balanceDue.toStringAsFixed(2),
      'footer': settings?.footerNote ?? 'Thank you for your business!',
    };
  }

  static Map<String, dynamic> fromPurchase(Purchase purchase, Supplier supplier, {ReceiptSettings? settings}) {
    final businessName = settings?.businessName ?? 'Zayi Enterprise';

    return {
      'receiptNumber': 'P-${purchase.id}',
      'issuer': businessName,
      'supplierName': supplier.name,
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(purchase.createdAt),
      'items': [
        {
          'name': 'Purchase Stock',
          'qty': purchase.crates,
          'total': purchase.totalCost.toStringAsFixed(2),
        },
      ],
      'subTotal': purchase.totalCost.toStringAsFixed(2),
      'total': purchase.totalCost.toStringAsFixed(2),
      'cash': purchase.totalCost.toStringAsFixed(2),
      'balance': '0.00',
      'footer': settings?.footerNote ?? 'Thank you for your business!',
    };
  }
}
