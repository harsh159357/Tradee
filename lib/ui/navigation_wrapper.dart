import 'package:flutter/material.dart';
import 'theme.dart';
import 'asset_selection_screen.dart';
import 'portfolio_screen.dart';
import 'risk_dashboard.dart';
import 'strategy_builder.dart';
import 'settings_screen.dart';

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

const _navItems = [
  _NavItem(Icons.candlestick_chart_outlined, Icons.candlestick_chart, 'Markets'),
  _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Portfolio'),
  _NavItem(Icons.hub_outlined, Icons.hub, 'Builder'),
  _NavItem(Icons.shield_outlined, Icons.shield, 'Risk'),
  _NavItem(Icons.tune_outlined, Icons.tune, 'Settings'),
];

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
    StrategyBuilderScreen(),
    RiskDashboard(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        if (isWide) {
          return _buildWideLayout();
        }
        return _buildNarrowLayout();
      },
    );
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryDim,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _navItems
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon, size: 22),
                    selectedIcon: Icon(item.selectedIcon, size: 22, color: AppColors.primary),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.surfaceBorder, width: 1),
              ),
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              extended: true,
              minExtendedWidth: 200,
              backgroundColor: Colors.transparent,
              leading: const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Row(
                  children: [
                    Icon(Icons.show_chart, color: AppColors.primary, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Tradee',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon, color: AppColors.primary),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
