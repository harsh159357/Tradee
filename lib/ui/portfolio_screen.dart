import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/risk_state.dart';
import 'widgets/empty_state.dart';
import 'widgets/stat_column.dart';

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
        appBar: AppBar(
          title: const Text('Portfolio'),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Positions'),
              Tab(text: 'History'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: Column(
          children: [
            _buildStatsHeader(context, marginStatus, realizedPnL),
            const Divider(color: Colors.white10, height: 1),
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
    );
  }

  Widget _buildStatsHeader(BuildContext context, MarginStatus status, double realizedPnL) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn('Equity', '\$${status.equity.toStringAsFixed(2)}',
                  Theme.of(context).colorScheme.primary),
              _statColumn('Used Margin', '\$${status.maintenanceMargin.toStringAsFixed(2)}',
                  Colors.white),
              _statColumn(
                'Available',
                '\$${status.availableMargin.toStringAsFixed(2)}',
                status.availableMargin >= 0 ? Colors.white70 : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn(
                'Unrealized',
                '${status.unrealizedPnL >= 0 ? "+" : ""}\$${status.unrealizedPnL.toStringAsFixed(2)}',
                status.unrealizedPnL >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
              _statColumn(
                'Realized',
                '${realizedPnL >= 0 ? "+" : ""}\$${realizedPnL.toStringAsFixed(2)}',
                realizedPnL >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return StatColumn(label: label, value: value, valueColor: color);
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
        message: 'No active positions',
      );
    }

    return ListView.builder(
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final pos = positions[index];
        return _buildPositionCard(context, ref, pos, marks[pos.id]);
      },
    );
  }

  Widget _buildPositionCard(
    BuildContext context,
    WidgetRef ref,
    Position pos,
    PositionMark? mark,
  ) {
    final pnl = mark?.pnl ?? 0.0;
    final isProfit = pnl >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${pos.symbol} ${pos.strike.toStringAsFixed(0)} ${pos.type.toUpperCase()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (!pos.isFilled)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('LIMIT',
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.black)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pos.quantity > 0 ? "LONG" : "SHORT"} ${pos.quantity.abs()} @ \$${pos.entryPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                      if (pos.isFilled && mark != null)
                        Text(
                          'Mark: \$${mark.premium.toStringAsFixed(2)}  IV: ${(mark.iv * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pos.isFilled
                          ? '${isProfit ? "+" : ""}\$${pnl.toStringAsFixed(2)}'
                          : 'PENDING',
                      style: TextStyle(
                        color: pos.isFilled
                            ? (isProfit
                                ? Colors.greenAccent
                                : Colors.redAccent)
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (pos.isFilled)
                      const Text('Unrealized',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 9)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
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
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
              child:
                  Text(pos.isFilled ? 'CLOSE POSITION' : 'CANCEL ORDER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(List<TradeRecord> history) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        message: 'No trade history yet',
      );
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final trade = history[index];
        final isProfit = trade.realizedPnL >= 0;

        return ListTile(
          dense: true,
          title: Text(
            '${trade.symbol} ${trade.strike.toStringAsFixed(0)} ${trade.type.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          subtitle: Text(
            '${trade.quantity > 0 ? "LONG" : "SHORT"} ${trade.quantity.abs()} | '
            'Entry: \$${trade.entryPrice.toStringAsFixed(2)} → Exit: \$${trade.exitPrice.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          trailing: Text(
            '${isProfit ? "+" : ""}\$${trade.realizedPnL.toStringAsFixed(2)}',
            style: TextStyle(
              color: isProfit ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }
}
