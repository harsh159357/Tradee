import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/market_state.dart';
import '../engines/pricing_engine.dart';
import '../features/risk_state.dart';

class RiskDashboard extends HookConsumerWidget {
  const RiskDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(portfolioProvider);
    final prices = ref.watch(pricesProvider).value ?? {};
    final t = ref.watch(tValueProvider).value ?? 0.0;
    final marginStatus = ref.watch(marginStatusProvider);

    if (marginStatus.isLiquidated) {
      // Auto-liquidation side effect (simplified)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final pos in positions) {
          ref.read(portfolioProvider.notifier).closePosition(pos.id);
        }
      });
    }

    double netDelta = 0;
    double netGamma = 0;
    double netVega = 0;
    double netTheta = 0;

    for (final pos in positions) {
      if (!pos.isFilled) continue;
      final spot = prices[pos.symbol] ?? 0.0;
      final res = BlackScholesEngine.calculate(
        S: spot,
        K: pos.strike,
        T: t,
        r: 0.05,
        v: 0.50,
        type: pos.type == 'call' ? OptionType.call : OptionType.put,
      );

      netDelta += res.delta * pos.quantity;
      netGamma += res.gamma * pos.quantity;
      netVega += res.vega * pos.quantity;
      netTheta += res.theta * pos.quantity;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Management'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (marginStatus.isLiquidated)
            const Card(
              color: Colors.redAccent,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('LIQUIDATION TRIGGERED: Positions Closed', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          _buildGreekTile('Net Delta', netDelta, 'Sensitivity to price'),
          _buildGreekTile('Net Gamma', netGamma, 'Sensitivity to delta'),
          _buildGreekTile('Net Vega', netVega, 'Sensitivity to volatility'),
          _buildGreekTile('Net Theta', netTheta, 'Time decay per day'),
          const SizedBox(height: 24),
          _buildSummaryCard(marginStatus),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(MarginStatus status) {
    return Card(
      color: const Color(0xFF1E2329),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Equity/Margin Ratio', style: TextStyle(color: Colors.white54)),
                Text('${(status.equity / (status.maintenanceMargin == 0 ? 1 : status.maintenanceMargin) * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: status.maintenanceMargin / (status.equity == 0 ? 1 : status.equity),
              color: Colors.orangeAccent,
              backgroundColor: Colors.white10,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGreekTile(String label, double value, String desc) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: Text(
        value.toStringAsFixed(4),
        style: TextStyle(
          color: value >= 0 ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
