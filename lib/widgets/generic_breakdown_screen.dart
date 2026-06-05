import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/insta_theme.dart';
import '../services/toast_service.dart';

class GenericBreakdownScreen extends ConsumerStatefulWidget {
  final String title;
  final List<Map<String, dynamic>>? items;
  final Widget Function(BuildContext, Map<String, dynamic>) itemBuilder;
  final Widget? headerWidget;
  final ProviderBase<AsyncValue<List<Map<String, dynamic>>>>? dataProvider;

  const GenericBreakdownScreen({
    super.key,
    required this.title,
    this.items,
    required this.itemBuilder,
    this.headerWidget,
    this.dataProvider,
  });

  @override
  ConsumerState<GenericBreakdownScreen> createState() => _GenericBreakdownScreenState();
}

class _GenericBreakdownScreenState extends ConsumerState<GenericBreakdownScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncData = widget.dataProvider != null ? ref.watch(widget.dataProvider!) : null;
    final items = widget.items ?? asyncData?.value ?? [];

    if (asyncData?.hasError == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastService.show(context, 'Error: ${asyncData!.error}', isError: true);
      });
    }

    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: InstaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        foregroundColor: InstaPalette.textPrimary,
        elevation: 0.5,
      ),
      body: asyncData != null && asyncData.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.headerWidget != null) widget.headerWidget!,
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No data available.', style: TextStyle(color: InstaPalette.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => widget.itemBuilder(context, items[index]),
                        ),
                ),
              ],
            ),
    );
  }
}
