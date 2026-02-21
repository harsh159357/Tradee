import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/market_state.dart';
import '../engines/pricing_engine.dart';
import '../features/risk_state.dart';

class PortfolioScreen extends HookConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(portfolioProvider);
    final marginStatus = ref.watch(marginStatusProvider);
    final prices = ref.watch(pricesProvider).value ?? {};
    final t = ref.watch(tValueProvider).value ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          _buildStatsHeader(marginStatus.equity, marginStatus.maintenanceMargin),
          const Divider(color: Colors.white10),
          Expanded(
            child: positions.isEmpty 
              ? const Center(child: Text('No active positions', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final pos = positions[index];
                    return _buildPositionCard(context, ref, pos, prices, t);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(double equity, double margin) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('Equity', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('\$${equity.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF0B90B))),
            ],
          ),
          Column(
            children: [
              const Text('Margin Used', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('\$${margin.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(BuildContext context, WidgetRef ref, Position pos, Map<String, double> prices, double t) {
    final spot = prices[pos.symbol] ?? 0.0;
    
    // Calculate current premium for PnL
    final currentRes = BlackScholesEngine.calculate(
      S: spot,
      K: pos.strike,
      T: t,
      r: 0.05,
      v: 0.50, 
      type: pos.type == 'call' ? OptionType.call : OptionType.put,
    );

    final pnl = (currentRes.premium - pos.entryPrice) * pos.quantity;
    final isProfit = pnl >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${pos.symbol} ${pos.strike.toStringAsFixed(0)} ${pos.type.toUpperCase()}', 
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (!pos.isFilled)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                            child: const Text('LIMIT', style: TextStyle(fontSize: 10, color: Colors.black)),
                          ),
                      ],
                    ),
                    Text('${pos.quantity > 0 ? "LONG" : "SHORT"} ${pos.quantity.abs()} Contracts @ \$${pos.entryPrice.toStringAsFixed(2)}', 
                         style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pos.isFilled ? '${isProfit ? "+" : ""}\$${pnl.toStringAsFixed(2)}' : 'PENDING',
                      style: TextStyle(
                        color: pos.isFilled ? (isProfit ? Colors.greenAccent : Colors.redAccent) : Colors.orange, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18
                      ),
                    ),
                    if (pos.isFilled) const Text('Unrealized PnL', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(portfolioProvider.notifier).closePosition(pos.id),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              child: Text(pos.isFilled ? 'CLOSE POSITION' : 'CANCEL ORDER'),
            )
          ],
        ),
      ),
    );
  }
}
