import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../theme/insta_theme.dart';
import 'full_page_add_dialog.dart';

class QuickAddDialogs {
  static void showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => _SupplierForm()));
  }

  static void showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => _CustomerForm()));
  }
}

class _SupplierForm extends ConsumerStatefulWidget {
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
  Widget build(BuildContext context) {
    return FullPageAddDialog(
      title: 'Add New Supplier',
      isSaving: isSaving,
      onSave: () async {
        if (nameController.text.isNotEmpty) {
          setState(() => isSaving = true);
          try {
            final supplier = Supplier(
              name: nameController.text,
              phone: phoneController.text,
              location: locationController.text,
              notes: notesController.text,
              createdAt: DateTime.now(),
            );
            await DatabaseHelper.instance.createSupplier(supplier);
            ref.read(suppliersProvider.notifier).refresh();
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier added successfully')));
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
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.phone),
          TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
        ],
      ),
    );
  }
}

class _CustomerForm extends ConsumerStatefulWidget {
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
  Widget build(BuildContext context) {
    return FullPageAddDialog(
      title: 'Add New Customer',
      isSaving: isSaving,
      onSave: () async {
        if (nameController.text.isNotEmpty) {
          setState(() => isSaving = true);
          try {
            final customer = Customer(
              name: nameController.text,
              phone: phoneController.text,
              location: locationController.text,
              notes: notesController.text,
              createdAt: DateTime.now(),
            );
            await DatabaseHelper.instance.createCustomer(customer);
            ref.read(customersProvider.notifier).refresh();
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer added successfully')));
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
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: InstaPalette.textSecondary)), keyboardType: TextInputType.phone),
          TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
          TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: InstaPalette.textSecondary))),
        ],
      ),
    );
  }
}
