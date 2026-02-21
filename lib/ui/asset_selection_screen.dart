import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/market_state.dart';
import 'trading_screen.dart';

class AssetSelectionScreen extends HookConsumerWidget {
  const AssetSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(pricesProvider).value ?? {};
    final assets = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Asset'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final symbol = assets[index];
          final price = prices[symbol] ?? 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(symbol, style: Theme.of(context).textTheme.titleLarge),
              trailing: Text(
                price > 0 ? '\$${price.toStringAsFixed(2)}' : 'Loading...',
                style: const TextStyle(
                  color: Color(0xFFF0B90B),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                ref.read(selectedAssetProvider.notifier).state = symbol;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TradingScreen()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
