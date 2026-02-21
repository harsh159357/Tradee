import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/market_state.dart';
import '../engines/pricing_engine.dart';

class RiskDashboard extends HookConsumerWidget {
  const RiskDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(portfolioProvider);
    final prices = ref.watch(pricesProvider).value ?? {};
    final t = ref.watch(tValueProvider).value ?? 0.0;

    double netDelta = 0;
    double netGamma = 0;
    double netVega = 0;
    double netTheta = 0;

    for (final pos in positions) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildGreekTile('Net Delta', netDelta, 'Sensitivity to price'),
            _buildGreekTile('Net Gamma', netGamma, 'Sensitivity to delta'),
            _buildGreekTile('Net Vega', netVega, 'Sensitivity to volatility'),
            _buildGreekTile('Net Theta', netTheta, 'Time decay per day'),
            const SizedBox(height: 24),
            const Card(
              color: Color(0xFF1E2329),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Stress Test (Not Implemented)', style: TextStyle(color: Colors.white54)),
                    // Stress test slider would go here
                  ],
                ),
              ),
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
