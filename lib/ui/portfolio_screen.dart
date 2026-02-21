import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/market_state.dart';
import '../engines/pricing_engine.dart';

class PortfolioScreen extends HookConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(portfolioProvider);
    final balance = ref.watch(balanceProvider);
    final prices = ref.watch(pricesProvider).value ?? {};
    final t = ref.watch(tValueProvider).value ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          _buildStatsHeader(balance),
          const Divider(color: Colors.white10),
          Expanded(
            child: positions.isEmpty 
              ? const Center(child: Text('No active positions', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final pos = positions[index];
                    return _buildPositionCard(context, ref, pos, prices, t, index);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Total Equity', style: TextStyle(color: Colors.white54, fontSize: 14)),
          Text('\$${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF0B90B))),
        ],
      ),
    );
  }

  Widget _buildPositionCard(BuildContext context, WidgetRef ref, Position pos, Map<String, double> prices, double t, int index) {
    final spot = prices[pos.symbol] ?? 0.0;
    
    // Calculate current premium for PnL
    final currentRes = BlackScholesEngine.calculate(
      S: spot,
      K: pos.strike,
      T: t,
      r: 0.05,
      v: 0.50, // Simplified for UI
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
                    Text('${pos.symbol} ${pos.strike.toStringAsFixed(0)} ${pos.type.toUpperCase()}', 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${pos.quantity > 0 ? "LONG" : "SHORT"} ${pos.quantity.abs()} Contracts', 
                         style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isProfit ? "+" : ""}\$${pnl.toStringAsFixed(2)}',
                      style: TextStyle(color: isProfit ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Text('Unrealized PnL', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(portfolioProvider.notifier).closePosition(index),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              child: const Text('CLOSE POSITION'),
            )
          ],
        ),
      ),
    );
  }
}
