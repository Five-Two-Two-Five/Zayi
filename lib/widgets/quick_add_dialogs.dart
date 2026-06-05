import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../theme/insta_theme.dart';
import 'full_page_add_dialog.dart';

import '../models/equity_transaction.dart';

class QuickAddDialogs {
  static void showAddSupplierDialog(BuildContext context, WidgetRef ref, {Supplier? supplier}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => _SupplierForm(supplier: supplier)));
  }

  static void showAddCustomerDialog(BuildContext context, WidgetRef ref, {Customer? customer}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => _CustomerForm(customer: customer)));
  }

  static void showEquityDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const _EquityForm()));
  }
}

class _EquityForm extends ConsumerStatefulWidget {
  const _EquityForm();

  @override
  ConsumerState<_EquityForm> createState() => _EquityFormState();
}

class _EquityFormState extends ConsumerState<_EquityForm> {
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  EquityType selectedType = EquityType.contribution;
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return FullPageAddDialog(
      title: 'Record Equity Transaction',
      isSaving: isSaving,
      onSave: () async {
        final amount = double.tryParse(amountController.text);
        if (amount != null && amount > 0) {
          setState(() => isSaving = true);
          try {
            final tx = EquityTransaction(
              type: selectedType,
              amount: amount,
              notes: notesController.text,
              createdAt: DateTime.now(),
            );
            await DatabaseHelper.instance.createEquityTransaction(tx.toMap());
            ref.read(equityProvider.notifier).refresh();
            ref.invalidate(dashboardSummaryProvider);
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equity transaction recorded')));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            if (mounted) setState(() => isSaving = false);
          }
        }
      },
      child: Column(
        children: [
          DropdownButtonFormField<EquityType>(
            initialValue: selectedType,
            decoration: const InputDecoration(labelText: 'Transaction Type', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
            items: const [
              DropdownMenuItem(value: EquityType.contribution, child: Text('Capital Contribution (In)', style: TextStyle(color: InstaPalette.textPrimary))),
              DropdownMenuItem(value: EquityType.drawing, child: Text('Owner Drawing (Out)', style: TextStyle(color: InstaPalette.textPrimary))),
            ],
            onChanged: (val) => setState(() => selectedType = val!),
          ),
          TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount *', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.number),
          TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
        ],
      ),
    );
  }
}

class _SupplierForm extends ConsumerStatefulWidget {
  final Supplier? supplier;
  const _SupplierForm({this.supplier});

  @override
  ConsumerState<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<_SupplierForm> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      nameController.text = widget.supplier!.name;
      phoneController.text = widget.supplier!.phone;
      locationController.text = widget.supplier!.location;
      notesController.text = widget.supplier!.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullPageAddDialog(
      title: widget.supplier == null ? 'Add New Supplier' : 'Edit Supplier',
      isSaving: isSaving,
      onSave: () async {
        if (nameController.text.isNotEmpty) {
          setState(() => isSaving = true);
          try {
            final supplier = Supplier(
              id: widget.supplier?.id,
              name: nameController.text,
              phone: phoneController.text,
              location: locationController.text,
              notes: notesController.text,
              createdAt: widget.supplier?.createdAt ?? DateTime.now(),
            );
            if (widget.supplier == null) {
              await DatabaseHelper.instance.createSupplier(supplier);
            } else {
              await DatabaseHelper.instance.updateSupplier(supplier);
            }
            ref.read(suppliersProvider.notifier).refresh();
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(widget.supplier == null
                    ? 'Supplier added successfully'
                    : 'Supplier updated successfully')));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            if (mounted) setState(() => isSaving = false);
          }
        }
      },
      child: Column(
        children: [
          TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Name *', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                  labelText: 'Phone *', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
              keyboardType: TextInputType.phone),
          TextField(
              controller: locationController,
              decoration: const InputDecoration(
                  labelText: 'Location (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(
              controller: notesController,
              decoration: const InputDecoration(
                  labelText: 'Notes (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
        ],
      ),
    );
  }
}

class _CustomerForm extends ConsumerStatefulWidget {
  final Customer? customer;
  const _CustomerForm({this.customer});

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      nameController.text = widget.customer!.name;
      phoneController.text = widget.customer!.phone;
      locationController.text = widget.customer!.location;
      notesController.text = widget.customer!.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullPageAddDialog(
      title: widget.customer == null ? 'Add New Customer' : 'Edit Customer',
      isSaving: isSaving,
      onSave: () async {
        if (nameController.text.isNotEmpty) {
          setState(() => isSaving = true);
          try {
            final customer = Customer(
              id: widget.customer?.id,
              name: nameController.text,
              phone: phoneController.text,
              location: locationController.text,
              notes: notesController.text,
              createdAt: widget.customer?.createdAt ?? DateTime.now(),
            );
            if (widget.customer == null) {
              await DatabaseHelper.instance.createCustomer(customer);
            } else {
              await DatabaseHelper.instance.updateCustomer(customer);
            }
            ref.read(customersProvider.notifier).refresh();
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(widget.customer == null
                    ? 'Customer added successfully'
                    : 'Customer updated successfully')));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            if (mounted) setState(() => isSaving = false);
          }
        }
      },
      child: Column(
        children: [
          TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Name *', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                  labelText: 'Phone *', labelStyle: TextStyle(color: InstaPalette.textSecondary)),
              keyboardType: TextInputType.phone),
          TextField(
              controller: locationController,
              decoration: const InputDecoration(
                  labelText: 'Location (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(
              controller: notesController,
              decoration: const InputDecoration(
                  labelText: 'Notes (Optional)', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
        ],
      ),
    );
  }
}
