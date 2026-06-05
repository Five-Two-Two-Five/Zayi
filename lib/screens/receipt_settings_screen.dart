import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/providers.dart';
import '../models/receipt_settings.dart';
import '../theme/insta_theme.dart';
import '../features/receipts/services/logo_service.dart';

class ReceiptSettingsForm extends ConsumerStatefulWidget {
  const ReceiptSettingsForm({super.key});

  @override
  ConsumerState<ReceiptSettingsForm> createState() => _ReceiptSettingsFormState();
}

class _ReceiptSettingsFormState extends ConsumerState<ReceiptSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _footerController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  String? _logoPath;
  String? _originalLogoPath;
  String _baseCurrency = 'USD';
  List<Map<String, dynamic>> _predefinedTaxes = [];

  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _footerController.dispose();
    _taxRateController.dispose();
    _exchangeRateController.dispose();
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
    _taxRateController.text = settings.defaultTaxRate.toString();
    _exchangeRateController.text = settings.defaultExchangeRate.toString();
    _logoPath = settings.logoPath;
    _originalLogoPath = settings.logoPath;
    _baseCurrency = settings.baseCurrency;
    _predefinedTaxes = List<Map<String, dynamic>>.from(settings.predefinedTaxes);
    _isInitialized = true;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing image...')),
    );
    
    final processedPath = await LogoService.processAndSaveLogo(image.path);
    
    if (!context.mounted) return; 
    
    if (processedPath != null) {
      setState(() {
        _logoPath = processedPath;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image format')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(receiptSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        _initFields(settings);
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard('Business Identity', [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: InstaPalette.cardBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: InstaPalette.border)),
                          child: _logoPath != null ? ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.file(File(_logoPath!), fit: BoxFit.contain)) : const Icon(Icons.add_a_photo, color: InstaPalette.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_logoPath != null)
                        TextButton(onPressed: () => setState(() => _logoPath = null), child: const Text('Remove Logo', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(_nameController, 'Business Name', Icons.business, isRequired: true),
                  _buildTextFormField(_addressController, 'Address', Icons.location_on, maxLines: 2),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard('Contact & Tax', [
                  Row(
                    children: [
                      Expanded(child: _buildTextFormField(_phoneController, 'Phone', Icons.phone, keyboardType: TextInputType.phone)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextFormField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress)),
                    ],
                  ),
                  _buildTextFormField(_taxIdController, 'Tax ID', Icons.receipt_long),
                  _buildTextFormField(_taxRateController, 'Default Tax Rate (%)', Icons.percent, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 16),
                  const Text('PREDEFINED TAXES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
                  _buildTaxManager(),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard('Reporting & Footer', [
                  _buildCurrencySelector(),
                  _buildTextFormField(_exchangeRateController, 'Exchange Rate', Icons.currency_exchange, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  _buildTextFormField(_footerController, 'Footer Note', Icons.notes),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (_logoPath != _originalLogoPath && _originalLogoPath != null) {
                        await LogoService.deleteLogo(_originalLogoPath);
                      }
                      final newSettings = ReceiptSettings(
                        businessName: _nameController.text,
                        address: _addressController.text,
                        taxId: _taxIdController.text,
                        phone: _phoneController.text,
                        email: _emailController.text,
                        footerNote: _footerController.text,
                        defaultTaxRate: double.tryParse(_taxRateController.text) ?? 0.0,
                        defaultExchangeRate: double.tryParse(_exchangeRateController.text) ?? 1.0,
                        logoPath: _logoPath,
                        baseCurrency: _baseCurrency,
                        predefinedTaxes: _predefinedTaxes,
                        paymentMethodCharges: settings.paymentMethodCharges,
                      );
                      await ref.read(receiptSettingsProvider.notifier).updateSettings(newSettings);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
                    },
                    child: const Text('SAVE SETTINGS'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: InstaPalette.accent)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: InstaPalette.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: InstaPalette.textSecondary, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildTaxManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._predefinedTaxes.asMap().entries.map((entry) {
          final idx = entry.key;
          final tax = entry.value;
          return Row(
            children: [
              Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Label', isDense: true), initialValue: tax['label'], onChanged: (v) => _predefinedTaxes[idx]['label'] = v)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Rate %', isDense: true), initialValue: tax['rate'].toString(), onChanged: (v) => _predefinedTaxes[idx]['rate'] = double.tryParse(v) ?? 0.0)),
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() => _predefinedTaxes.removeAt(idx))),
            ],
          );
        }),
        TextButton.icon(onPressed: () => setState(() => _predefinedTaxes.add({'label': '', 'rate': 0.0})), icon: const Icon(Icons.add), label: const Text('Add Tax')),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Base Currency', style: TextStyle(fontSize: 12, color: InstaPalette.textSecondary)),
        DropdownButtonFormField<String>(
          value: _baseCurrency,
          items: ['USD', 'ZiG'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _baseCurrency = v!),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ],
    );
  }
}
