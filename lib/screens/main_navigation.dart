import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'sale_screen.dart';
import 'purchase_screen.dart';
import 'reports_screen.dart';
import 'management_screen.dart';
import 'product_selection_screen.dart';
import 'settings_screen.dart';
import '../providers/providers.dart';
import '../theme/insta_theme.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const SaleScreen(),
    const PurchaseScreen(),
    const ManagementScreen(),
    const ReportsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeProduct = ref.watch(activeProductProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeProduct?.name.toUpperCase() ?? 'ZAYI',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
        ),
        backgroundColor: InstaPalette.background,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.apps, color: InstaPalette.textPrimary),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProductSelectionScreen()),
            );
          },
          tooltip: 'Switch Product',
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final syncService = ref.watch(syncServiceProvider);
              final authState = ref.watch(authStateProvider);
              
              if (authState.value == null) return const SizedBox.shrink();

              return IconButton(
                icon: Icon(
                  syncService.isSyncing ? Icons.sync : Icons.cloud_done,
                  color: syncService.isSyncing ? InstaPalette.accent : Colors.green,
                ),
                onPressed: () => syncService.syncAll(),
                tooltip: 'Sync with Cloud',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: InstaPalette.textPrimary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        backgroundColor: InstaPalette.background,
        selectedItemColor: InstaPalette.accent,
        unselectedItemColor: InstaPalette.textSecondary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Purchases'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Management'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

