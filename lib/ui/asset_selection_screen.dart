import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../data/market_data_service.dart' show WsConnectionState;
import '../domain/price_point.dart';
import '../features/market_state.dart';
import 'theme.dart';

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

  static const _assetColors = {
    'BTCUSDT': Color(0xFFF7931A),
    'ETHUSDT': Color(0xFF627EEA),
    'SOLUSDT': Color(0xFF9945FF),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(pricesProvider);
    final prices = pricesAsync.value ?? {};
    final change24h = ref.watch(change24hProvider).value ?? {};
    final history = ref.watch(priceHistoryProvider).value ?? {};
    const assets = AppConstants.supportedAssets;
    final te = ref.watch(timeProvider);
    final countdown = te.getCountdown();
    final connState = ref.watch(connectionStateProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Markets',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            _buildConnectionDot(connState),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    countdown,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exp ${te.expiryIST}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final symbol = assets[index];
                    final price = prices[symbol] ?? 0.0;
                    final pctChange = change24h[symbol] ?? 0.0;
                    final points = history[symbol] ?? [];
                    final assetColor = _assetColors[symbol] ?? AppColors.primary;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AssetCard(
                        symbol: symbol,
                        name: _assetNames[symbol] ?? symbol,
                        icon: _assetIcons[symbol] ?? Icons.monetization_on,
                        color: assetColor,
                        price: price,
                        pctChange: pctChange,
                        history: points,
                        onTap: () {
                          ref.read(selectedAssetProvider.notifier).state = symbol;
                          context.push('/trade');
                        },
                      ),
                    );
                  },
                  childCount: assets.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDot(AsyncValue<WsConnectionState> connState) {
    return connState.when(
      data: (state) {
        Color color;
        String tooltip;
        switch (state) {
          case WsConnectionState.connected:
            color = AppColors.profit;
            tooltip = 'Connected';
          case WsConnectionState.reconnecting:
            color = Colors.orange;
            tooltip = 'Reconnecting...';
          case WsConnectionState.disconnected:
            color = AppColors.loss;
            tooltip = 'Disconnected';
        }
        return Tooltip(
          message: tooltip,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 6)],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final String symbol;
  final String name;
  final IconData icon;
  final Color color;
  final double price;
  final double pctChange;
  final List<PricePoint> history;
  final VoidCallback onTap;

  const _AssetCard({
    required this.symbol,
    required this.name,
    required this.icon,
    required this.color,
    required this.price,
    required this.pctChange,
    required this.history,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withAlpha(40), color.withAlpha(15)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol.replaceAll('USDT', ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (history.length >= 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 64,
                    height: 32,
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        points: history,
                        color: pctChange >= 0 ? AppColors.profit : AppColors.loss,
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price > 0 ? '\$${_formatPrice(price)}' : '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ChangeBadge(pctChange: pctChange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1) return p.toStringAsFixed(2);
    return p.toStringAsFixed(4);
  }
}

class _ChangeBadge extends StatelessWidget {
  final double pctChange;
  const _ChangeBadge({required this.pctChange});

  @override
  Widget build(BuildContext context) {
    final isPositive = pctChange >= 0;
    final color = isPositive ? AppColors.profit : AppColors.loss;
    final bgColor = isPositive ? AppColors.profitDim : AppColors.lossDim;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isPositive ? "+" : ""}${pctChange.toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<PricePoint> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final prices = points.map((p) => p.price).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = maxP - minP;
    if (range == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < prices.length; i++) {
      final x = i / (prices.length - 1) * size.width;
      final y = size.height - ((prices[i] - minP) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points.length != points.length;
}
