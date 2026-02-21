import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'asset_selection_screen.dart';
import 'portfolio_screen.dart';
import 'risk_dashboard.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    AssetSelectionScreen(),
    PortfolioScreen(),
    RiskDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Markets'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Risk'),
        ],
      ),
    );
  }
}
