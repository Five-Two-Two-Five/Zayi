import 'package:flutter/material.dart';
import '../theme/insta_theme.dart';

class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: InstaPalette.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: InstaPalette.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: InstaPalette.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: children.map((child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: child,
              );
            }).toList()..removeLast(),
          ),
        ),
      ],
    );
  }
}

class FormRow extends StatelessWidget {
  final List<Widget> children;

  const FormRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((entry) {
        final isLast = entry.key == children.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: entry.value,
          ),
        );
      }).toList(),
    );
  }
}
