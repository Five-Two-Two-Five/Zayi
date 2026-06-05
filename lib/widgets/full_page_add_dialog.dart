import 'package:flutter/material.dart';
import '../theme/insta_theme.dart';

class FullPageAddDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;
  final bool isSaving;

  const FullPageAddDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isSaving ? null : () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : onSave,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            child,
            if (isSaving) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: InstaPalette.accent),
            ],
          ],
        ),
      ),
    );
  }
}
