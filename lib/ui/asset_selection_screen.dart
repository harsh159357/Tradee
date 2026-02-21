import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/market_state.dart';
import 'trading_screen.dart';

class AssetSelectionScreen extends HookConsumerWidget {
  const AssetSelectionScreen({super.key});

  static const _assetIcons = {
    'BTCUSDT': Icons.currency_bitcoin,
    'ETHUSDT': Icons.diamond_outlined,
    'SOLUSDT': Icons.wb_sunny_outlined,
  };

  static const _assetNames = {
    'BTCUSDT': 'Bitcoin',
    'ETHUSDT': 'Ethereum',
    'SOLUSDT': 'Solana',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(pricesProvider).value ?? {};
    final change24h = ref.watch(change24hProvider).value ?? {};
    final assets = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'];
    final te = ref.watch(timeProvider);
    final countdown = te.getCountdown();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text('$countdown  Exp ${te.expiryIST}',
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final symbol = assets[index];
          final price = prices[symbol] ?? 0.0;
          final pctChange = change24h[symbol] ?? 0.0;

          return Card(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                ref.read(selectedAssetProvider.notifier).state = symbol;
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const TradingScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0B90B).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _assetIcons[symbol] ?? Icons.monetization_on,
                        color: const Color(0xFFF0B90B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(symbol.replaceAll('USDT', ''),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text(_assetNames[symbol] ?? symbol,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price > 0
                              ? '\$${_formatPrice(price)}'
                              : 'Loading...',
                          style: const TextStyle(
                            color: Color(0xFFF0B90B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pctChange >= 0 ? "+" : ""}${pctChange.toStringAsFixed(2)}%  24h',
                          style: TextStyle(
                            color: pctChange >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(2);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(4);
    }
  }
}
