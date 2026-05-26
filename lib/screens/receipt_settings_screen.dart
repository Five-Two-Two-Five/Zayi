import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/receipt_settings.dart';
import '../theme/insta_theme.dart';

class ReceiptSettingsScreen extends ConsumerStatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  ConsumerState<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends ConsumerState<ReceiptSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _footerController = TextEditingController();

  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _initFields(ReceiptSettings settings) {
    if (_isInitialized) return;
    _nameController.text = settings.businessName;
    _addressController.text = settings.address;
    _taxIdController.text = settings.taxId;
    _phoneController.text = settings.phone;
    _emailController.text = settings.email;
    _footerController.text = settings.footerNote;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(receiptSettingsProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Receipt Settings', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final newSettings = ReceiptSettings(
                businessName: _nameController.text,
                address: _addressController.text,
                taxId: _taxIdController.text,
                phone: _phoneController.text,
                email: _emailController.text,
                footerNote: _footerController.text,
              );
              await ref.read(receiptSettingsProvider.notifier).updateSettings(newSettings);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt settings saved')),
              );
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          _initFields(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BUSINESS IDENTITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'Business Name', Icons.business),
                const SizedBox(height: 12),
                _buildTextField(_addressController, 'Address', Icons.location_on, maxLines: 3),
                const SizedBox(height: 24),
                const Text('CONTACT & TAX', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
                const SizedBox(height: 16),
                _buildTextField(_taxIdController, 'Tax ID / VAT Number', Icons.receipt_long),
                const SizedBox(height: 12),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                const Text('FOOTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
                const SizedBox(height: 16),
                _buildTextField(_footerController, 'Footer Note (e.g. Thank you!)', Icons.notes, maxLines: 2),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'These details will appear at the top of your generated receipts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: InstaPalette.textSecondary),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: InstaPalette.accent)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: InstaPalette.textSecondary, size: 20),
        labelStyle: const TextStyle(color: InstaPalette.textSecondary),
        alignLabelWithHint: true,
      ),
      style: const TextStyle(color: InstaPalette.textPrimary),
    );
  }
}
