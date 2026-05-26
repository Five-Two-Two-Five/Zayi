import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/insta_theme.dart';

class GenericBreakdownScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Widget Function(BuildContext, Map<String, dynamic>) itemBuilder;

  const GenericBreakdownScreen({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
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
      ),
      body: items.isEmpty
          ? const Center(child: Text('No data available.', style: TextStyle(color: InstaPalette.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => itemBuilder(context, items[index]),
            ),
    );
  }
}
