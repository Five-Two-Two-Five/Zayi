// lib/features/receipts/presentation/providers/designer_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/receipt_template.dart';

class DesignerNotifier extends Notifier<ReceiptTemplate> {
  @override
  ReceiptTemplate build() {
    return ReceiptTemplate(
      id: 'default',
      name: 'Default Thermal',
      headerSettings: {'show': true, 'businessName': 'My Business', 'address': '123 Main St'},
      footerSettings: {'show': true, 'message': 'Thank you!'},
    );
  }

  void updateHeader(Map<String, dynamic> newSettings) {
    state = ReceiptTemplate(
      id: state.id,
      name: state.name,
      headerSettings: {...state.headerSettings, ...newSettings},
      footerSettings: state.footerSettings,
      styling: state.styling,
    );
  }
}

final designerProvider = NotifierProvider<DesignerNotifier, ReceiptTemplate>(() {
  return DesignerNotifier();
});
