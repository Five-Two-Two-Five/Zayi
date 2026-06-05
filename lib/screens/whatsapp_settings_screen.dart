import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_whatsapp_settings.dart';
import '../database/database_helper.dart';
import '../theme/insta_theme.dart';

class WhatsAppSettingsScreen extends ConsumerStatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  ConsumerState<WhatsAppSettingsScreen> createState() => _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState extends ConsumerState<WhatsAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneIdController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _verifyTokenController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('WhatsApp Bot Setup', style: TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionCard(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneIdController,
                decoration: const InputDecoration(labelText: 'Phone Number ID', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accessTokenController,
                decoration: const InputDecoration(labelText: 'Access Token', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _verifyTokenController,
                decoration: const InputDecoration(labelText: 'Verify Token', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  child: _isSaving ? const CircularProgressIndicator() : const Text('SAVE SETTINGS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InstaPalette.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstaPalette.accent),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to setup your WhatsApp Bot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text('1. Go to developers.facebook.com and create an account.'),
          Text('2. Create a "Business" app, and add the "WhatsApp" product.'),
          Text('3. In the WhatsApp API dashboard, you will see "Phone Number ID" and "Access Token".'),
          Text('4. For "Verify Token", you can create any secret word you want (e.g., "zayi_secret_123").'),
          Text('5. Copy those values here and save!'),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final settings = BusinessWhatsappSettings(
      businessName: _nameController.text,
      phoneNumberId: _phoneIdController.text,
      accessToken: _accessTokenController.text,
      verifyToken: _verifyTokenController.text,
      createdAt: DateTime.now(),
    );

    await DatabaseHelper.instance.saveWhatsappSettings(settings);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp settings saved!')));
      Navigator.pop(context);
    }
  }
}
