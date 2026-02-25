import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/risk_state.dart';
import 'theme.dart';
import 'widgets/empty_state.dart';
import 'widgets/pnl_badge.dart';

class PortfolioScreen extends HookConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(portfolioProvider);
    final history = ref.watch(tradeHistoryProvider);
    final marginStatus = ref.watch(marginStatusProvider);
    final marks = ref.watch(positionMarksProvider);
    final realizedPnL = ref.watch(realizedPnLProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildEquityHero(context, marginStatus, realizedPnL),
              _buildTabBar(context),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPositionsTab(context, ref, positions, marks),
                    _buildHistoryTab(history),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquityHero(BuildContext context, MarginStatus status, double realizedPnL) {
    final marginRatio = status.equity > 0
        ? (status.maintenanceMargin / status.equity).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F26), Color(0xFF141820)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Equity',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${status.equity.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Unrealized',
                value: status.unrealizedPnL,
                showSign: true,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Realized',
                value: realizedPnL,
                showSign: true,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Margin ${(marginRatio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: marginRatio,
                        color: marginRatio < 0.5
                            ? AppColors.profit
                            : marginRatio < 0.8
                                ? Colors.orange
                                : AppColors.loss,
                        backgroundColor: AppColors.surfaceBorder,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: const TabBar(
        padding: EdgeInsets.all(4),
        tabs: [
          Tab(text: 'Positions'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildPositionsTab(
    BuildContext context,
    WidgetRef ref,
    List<Position> positions,
    Map<String, PositionMark> marks,
  ) {
    if (positions.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        message: 'No Active Positions',
        subtitle: 'Open a trade from the Markets screen',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final pos = positions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PositionCard(pos: pos, mark: marks[pos.id], ref: ref),
        );
      },
    );
  }

  Widget _buildHistoryTab(List<TradeRecord> history) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        message: 'No Trade History',
        subtitle: 'Completed trades will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final trade = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _HistoryTile(trade: trade),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final bool showSign;

  const _MiniStat({required this.label, required this.value, this.showSign = false});

  @override
  Widget build(BuildContext context) {
    final isProfit = value >= 0;
    final color = isProfit ? AppColors.profit : AppColors.loss;
    final sign = showSign ? (isProfit ? '+' : '') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          '$sign\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PositionCard extends StatelessWidget {
  final Position pos;
  final PositionMark? mark;
  final WidgetRef ref;

  const _PositionCard({required this.pos, this.mark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final pnl = mark?.pnl ?? 0.0;
    final isLong = pos.quantity > 0;
    final sideColor = isLong ? AppColors.profit : AppColors.loss;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${pos.symbol.replaceAll("USDT", "")} ${pos.strike.toStringAsFixed(0)} ${pos.type.toUpperCase()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (!pos.isFilled) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orange.withAlpha(80)),
                                    ),
                                    child: const Text(
                                      'LIMIT',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${isLong ? "LONG" : "SHORT"} ${pos.quantity.abs()} @ \$${pos.entryPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                            ),
                            if (pos.isFilled && mark != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Mark \$${mark!.premium.toStringAsFixed(2)}  ·  IV ${(mark!.iv * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (pos.isFilled)
                        PnLBadge(value: pnl)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(portfolioProvider.notifier).closePositionWithSettlement(
                          id: pos.id,
                          exitPrice: pos.isFilled ? (mark?.premium ?? 0.0) : 0.0,
                          isFilled: pos.isFilled,
                          pnl: pnl,
                          balanceNotifier: ref.read(balanceProvider.notifier),
                          currentBalance: ref.read(balanceProvider),
                          entryPrice: pos.entryPrice,
                          quantity: pos.quantity,
                          historyNotifier: ref.read(tradeHistoryProvider.notifier),
                        );
                      },
                      child: Text(
                        pos.isFilled ? 'CLOSE POSITION' : 'CANCEL ORDER',
                        style: const TextStyle(letterSpacing: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TradeRecord trade;
  const _HistoryTile({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.realizedPnL >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isProfit ? AppColors.profitDim : AppColors.lossDim),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isProfit ? Icons.trending_up : Icons.trending_down,
              size: 18,
              color: isProfit ? AppColors.profit : AppColors.loss,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trade.symbol.replaceAll("USDT", "")} ${trade.strike.toStringAsFixed(0)} ${trade.type.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trade.quantity > 0 ? "Long" : "Short"} ${trade.quantity.abs()}  ·  \$${trade.entryPrice.toStringAsFixed(2)} → \$${trade.exitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          PnLBadge(value: trade.realizedPnL, fontSize: 13),
        ],
      ),
    );
  }
}
