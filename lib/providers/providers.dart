import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/expense.dart';

// Suppliers Provider
final suppliersProvider = AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(() {
  return SuppliersNotifier();
});

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    return await DatabaseHelper.instance.getAllSuppliers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => DatabaseHelper.instance.getAllSuppliers());
  }
}

// Customers Provider
final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
  return CustomersNotifier();
});

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    return await DatabaseHelper.instance.getAllCustomers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => DatabaseHelper.instance.getAllCustomers());
  }
}

// Purchases Provider
final purchasesProvider = AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(() {
  return PurchasesNotifier();
});

class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() async {
    return await DatabaseHelper.instance.getAllPurchases();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => DatabaseHelper.instance.getAllPurchases());
  }
}

// Sales Provider
final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(() {
  return SalesNotifier();
});

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    return await DatabaseHelper.instance.getAllSales();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => DatabaseHelper.instance.getAllSales());
  }
}

// Expenses Provider
final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
  return ExpensesNotifier();
});

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return await DatabaseHelper.instance.getAllExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => DatabaseHelper.instance.getAllExpenses());
  }
}

// Inventory Provider
final inventoryBalanceProvider = FutureProvider<int>((ref) async {
  return await DatabaseHelper.instance.getInventoryBalance();
});

final inventoryBreakdownProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getInventoryBreakdown();
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

final dashboardDateRangeProvider = NotifierProvider<DashboardDateRangeNotifier, DateTimeRange?>(() {
  return DashboardDateRangeNotifier();
});

// Dashboard Summary Provider
final dashboardSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final range = ref.watch(dashboardDateRangeProvider);
  return await DatabaseHelper.instance.getSummaryInRange(range?.start, range?.end);
});
