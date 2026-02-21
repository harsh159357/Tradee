import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../data/storage_service.dart';

final volatilityModeProvider = StateProvider<String>((ref) {
  final box = StorageService.getBox(StorageService.boxSettings);
  return box.get('volatility_mode', defaultValue: 'rolling') as String;
});

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volMode = ref.watch(volatilityModeProvider);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Settings'), backgroundColor: Colors.transparent),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ACCOUNT',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset Demo Account'),
            subtitle: const Text(
                'Wipe all positions and reset balance to \$100,000'),
            onTap: () => _confirmReset(context, ref),
          ),
          const Divider(color: Colors.white10),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('VOLATILITY',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          RadioListTile<String>(
            title: const Text('Rolling Realized Vol (1h window)'),
            subtitle: const Text(
                'Calculated from live price data',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            value: 'rolling',
            groupValue: volMode,
            activeColor: const Color(0xFFF0B90B),
            onChanged: (v) => _setVolMode(ref, v!),
          ),
          RadioListTile<String>(
            title: const Text('Fixed 50% IV'),
            subtitle: const Text(
                'Constant implied volatility for all strikes',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            value: 'fixed',
            groupValue: volMode,
            activeColor: const Color(0xFFF0B90B),
            onChanged: (v) => _setVolMode(ref, v!),
          ),
          const Divider(color: Colors.white10),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ABOUT',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Tradee'),
            subtitle: Text('Crypto Daily Options Simulator',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: Text('v1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.calculate_outlined),
            title: Text('Pricing Model'),
            trailing: Text('Black-Scholes (European)'),
          ),
          const ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Expiry'),
            trailing: Text('Daily 23:59:59 UTC'),
          ),
        ],
      ),
    );
  }

  void _setVolMode(WidgetRef ref, String mode) {
    final box = StorageService.getBox(StorageService.boxSettings);
    box.put('volatility_mode', mode);
    ref.read(volatilityModeProvider.notifier).state = mode;
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Account?'),
        content:
            const Text('This will delete all positions, history, and reset balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final posBox =
                  StorageService.getBox(StorageService.boxPositions);
              final histBox =
                  StorageService.getBox(StorageService.boxHistory);
              await posBox.clear();
              await histBox.clear();
              await ref
                  .read(balanceProvider.notifier)
                  .updateBalance(100000.0);
              ref.read(portfolioProvider.notifier).loadPositions();
              ref.read(tradeHistoryProvider.notifier).refresh();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Account Reset Successful'),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('RESET',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
