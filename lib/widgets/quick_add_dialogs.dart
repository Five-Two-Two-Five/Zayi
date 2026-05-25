import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';

class QuickAddDialogs {
  static void showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Supplier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), enabled: !isSaving),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, enabled: !isSaving),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location'), enabled: !isSaving),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), enabled: !isSaving),
                if (isSaving) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Saving...'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
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
                    setState(() => isSaving = false);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static void showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), enabled: !isSaving),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, enabled: !isSaving),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location'), enabled: !isSaving),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), enabled: !isSaving),
                if (isSaving) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Saving...'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.isNotEmpty) {
                  setState(() => isSaving = true);
                  try {
                    final customer = Customer(
                      name: nameController.text,
                      phone: nameController.text.isEmpty ? '' : phoneController.text,
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
                    setState(() => isSaving = false);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
