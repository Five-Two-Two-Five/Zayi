import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as thermal;
import '../database/database_helper.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/fixed_asset.dart';
import '../models/equity_transaction.dart';
import '../models/receipt_settings.dart';
import '../models/product.dart';

// Product Providers
final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return await DatabaseHelper.instance.getAllProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => DatabaseHelper.instance.getAllProducts());
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.createProduct(product);
    await refresh();
  }
}

final activeProductProvider = StateProvider<Product?>((ref) => null);

// Receipt Settings Provider
final receiptSettingsProvider =
    AsyncNotifierProvider<ReceiptSettingsNotifier, ReceiptSettings>(() {
      return ReceiptSettingsNotifier();
    });

class ReceiptSettingsNotifier extends AsyncNotifier<ReceiptSettings> {
  @override
  Future<ReceiptSettings> build() async {
    final map = await DatabaseHelper.instance.getReceiptSettings();
    return ReceiptSettings.fromMap(map);
  }

  Future<void> updateSettings(ReceiptSettings settings) async {
    await DatabaseHelper.instance.updateReceiptSettings(settings.toMap());
    state = AsyncValue.data(settings);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// Suppliers Provider
final suppliersProvider =
    AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(() {
      return SuppliersNotifier();
    });

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    return await DatabaseHelper.instance.getAllSuppliers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => DatabaseHelper.instance.getAllSuppliers(),
    );
  }

  Future<void> editSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.updateSupplier(supplier);
    await refresh();
  }
}

// Customers Provider
final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
      return CustomersNotifier();
    });

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    return await DatabaseHelper.instance.getAllCustomers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => DatabaseHelper.instance.getAllCustomers(),
    );
  }

  Future<void> editCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    await refresh();
  }
}

// Purchases Provider
final purchasesProvider =
    AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(() {
      return PurchasesNotifier();
    });

class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() async {
    final activeProduct = ref.watch(activeProductProvider);
    return await DatabaseHelper.instance.getAllPurchases(productId: activeProduct?.id);
  }

  Future<void> refresh() async {
    final activeProduct = ref.read(activeProductProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => DatabaseHelper.instance.getAllPurchases(productId: activeProduct?.id),
    );
  }
}

// Sales Provider
final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(() {
  return SalesNotifier();
});

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    final activeProduct = ref.watch(activeProductProvider);
    return await DatabaseHelper.instance.getSales(limit: 1000, productId: activeProduct?.id);
  }

  Future<void> refresh() async {
    final activeProduct = ref.read(activeProductProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => DatabaseHelper.instance.getSales(limit: 1000, productId: activeProduct?.id),
    );
  }
}

// Expenses Provider
final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  () {
    return ExpensesNotifier();
  },
);

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return await DatabaseHelper.instance.getAllExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => DatabaseHelper.instance.getAllExpenses(),
    );
  }
}

// Assets Provider
final assetsProvider = AsyncNotifierProvider<AssetsNotifier, List<FixedAsset>>(
  () {
    return AssetsNotifier();
  },
);

class AssetsNotifier extends AsyncNotifier<List<FixedAsset>> {
  @override
  Future<List<FixedAsset>> build() async {
    final maps = await DatabaseHelper.instance.getAllFixedAssets();
    return maps.map((m) => FixedAsset.fromMap(m)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> editAsset(FixedAsset asset) async {
    await DatabaseHelper.instance.updateFixedAsset(asset);
    await refresh();
  }
}

// Equity Provider
final equityProvider =
    AsyncNotifierProvider<EquityNotifier, List<EquityTransaction>>(() {
      return EquityNotifier();
    });

class EquityNotifier extends AsyncNotifier<List<EquityTransaction>> {
  @override
  Future<List<EquityTransaction>> build() async {
    final maps = await DatabaseHelper.instance.getAllEquityTransactions();
    return maps.map((m) => EquityTransaction.fromMap(m)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// Inventory Provider
final inventoryBalanceProvider = FutureProvider<int>((ref) async {
  final activeProduct = ref.watch(activeProductProvider);
  return await DatabaseHelper.instance.getInventoryBalance(productId: activeProduct?.id);
});

final inventoryBreakdownProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final activeProduct = ref.watch(activeProductProvider);
  return await DatabaseHelper.instance.getInventoryBreakdown(productId: activeProduct?.id);
});

// Dashboard Filters
class DashboardDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() {
    final now = DateTime.now();
    // Default to Today
    return DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  void update(DateTimeRange? range) {
    state = range;
  }

  void setToday() {
    final now = DateTime.now();
    state = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  void setThisMonth() {
    final now = DateTime.now();
    state = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  void setAllTime() {
    state = null;
  }
}

final dashboardDateRangeProvider =
    NotifierProvider<DashboardDateRangeNotifier, DateTimeRange?>(() {
      return DashboardDateRangeNotifier();
    });

// Dashboard Summary Provider
final dashboardSummaryProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final range = ref.watch(dashboardDateRangeProvider);
  final currency = ref.watch(dashboardCurrencyFilterProvider);
  final method = ref.watch(dashboardPaymentMethodFilterProvider);
  final activeProduct = ref.watch(activeProductProvider);
  return await DatabaseHelper.instance.getSummaryInRange(
    range?.start,
    range?.end,
    currency: currency,
    paymentMethod: method,
    productId: activeProduct?.id,
  );
});

// Profit Trend Provider
final profitTrendProvider =
    AsyncNotifierProvider<ProfitTrendNotifier, List<Map<String, dynamic>>>(() {
      return ProfitTrendNotifier();
    });

class ProfitTrendNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final activeProduct = ref.watch(activeProductProvider);
    return await DatabaseHelper.instance.getDailyProfitTrend(30, productId: activeProduct?.id);
  }

  Future<void> refresh() async {
    final activeProduct = ref.read(activeProductProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => DatabaseHelper.instance.getDailyProfitTrend(30, productId: activeProduct?.id));
  }
}

// Expense Distribution Provider
final expenseDistributionProvider =
    AsyncNotifierProvider<
      ExpenseDistributionNotifier,
      List<Map<String, dynamic>>
    >(() {
      return ExpenseDistributionNotifier();
    });

class ExpenseDistributionNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return await DatabaseHelper.instance.getExpenseDistribution();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

final dashboardCurrencyFilterProvider = StateProvider<String?>((ref) => null);
final dashboardPaymentMethodFilterProvider = StateProvider<String?>(
  (ref) => null,
);

final currenciesProvider = FutureProvider<List<String>>((ref) async {
  return await DatabaseHelper.instance.getDistinctCurrencies();
});

final paymentMethodsProvider = FutureProvider<List<String>>((ref) async {
  return await DatabaseHelper.instance.getDistinctPaymentMethods();
});

final selectedPrinterProvider = StateProvider<thermal.BluetoothDevice?>((ref) => null);

final salePaymentsProvider =
    AsyncNotifierProvider.family<
      SalePaymentsNotifier,
      List<Map<String, dynamic>>,
      int
    >(() {
      return SalePaymentsNotifier();
    });

class SalePaymentsNotifier
    extends FamilyAsyncNotifier<List<Map<String, dynamic>>, int> {
  @override
  Future<List<Map<String, dynamic>>> build(int arg) async {
    return await DatabaseHelper.instance.getPaymentsForSale(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }
}

final salesBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({DateTimeRange? range, String? currency, String? paymentMethod})>((
      ref,
      arg,
    ) async {
      return await DatabaseHelper.instance.getSalesBreakdown(
        arg.range?.start,
        arg.range?.end,
        currency: arg.currency,
        paymentMethod: arg.paymentMethod,
      );
    });

final expensesBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({DateTimeRange? range, String? currency})>((
      ref,
      arg,
    ) async {
      return await DatabaseHelper.instance.getExpensesBreakdown(
        arg.range?.start,
        arg.range?.end,
        currency: arg.currency,
      );
    });

final debtBreakdownProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((
  ref,
  currency,
) async {
  return await DatabaseHelper.instance.getDebtBreakdown(currency: currency);
});

final taxBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({DateTimeRange? range, String? currency})>((
      ref,
      arg,
    ) async {
      return await DatabaseHelper.instance.getTaxBreakdown(
        arg.range?.start,
        arg.range?.end,
        currency: arg.currency,
      );
    });
