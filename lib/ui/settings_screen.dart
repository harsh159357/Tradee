import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../data/storage_service.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.transparent),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset Demo Account'),
            subtitle: const Text('Wipe all positions and reset balance to \$100,000'),
            onTap: () => _confirmReset(context, ref),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Account?'),
        content: const Text('This will delete all positions and history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final boxPos = StorageService.getBox(StorageService.boxPositions);
              await boxPos.clear();
              
              await ref.read(balanceProvider.notifier).updateBalance(100000.0);
              // Trigger reload in PortfolioNotifier
              ref.read(portfolioProvider.notifier).loadPositions();
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Reset Successful')));
            },
            child: const Text('RESET', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
