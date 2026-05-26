import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'sale_screen.dart';
import 'purchase_screen.dart';
import 'reports_screen.dart';
import 'management_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
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
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Purchases'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Management'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
