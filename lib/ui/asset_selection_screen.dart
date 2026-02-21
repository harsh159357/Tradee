import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../data/market_data_service.dart' show WsConnectionState;
import '../features/market_state.dart';

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
    final pricesAsync = ref.watch(pricesProvider);
    final prices = pricesAsync.value ?? {};
    final change24h = ref.watch(change24hProvider).value ?? {};
    const assets = AppConstants.supportedAssets;
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
      body: Column(
        children: [
          _buildConnectionBanner(ref),
          Expanded(
            child: ListView.builder(
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
                context.push('/trade');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _assetIcons[symbol] ?? Icons.monetization_on,
                        color: Theme.of(context).colorScheme.primary,
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(WidgetRef ref) {
    final connState = ref.watch(connectionStateProvider);
    return connState.when(
      data: (state) {
        if (state == WsConnectionState.connected) return const SizedBox.shrink();
        final isReconnecting = state == WsConnectionState.reconnecting;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          color: isReconnecting ? Colors.orange.shade800 : Colors.red.shade800,
          child: Row(
            children: [
              if (isReconnecting)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              if (!isReconnecting) const Icon(Icons.cloud_off, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                isReconnecting ? 'Reconnecting...' : 'Disconnected',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
