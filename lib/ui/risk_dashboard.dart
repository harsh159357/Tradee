import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/market_state.dart';
import '../engines/pricing_engine.dart';
import '../engines/volatility_engine.dart';
import '../features/risk_state.dart';

class RiskDashboard extends HookConsumerWidget {
  const RiskDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(portfolioProvider);
    final prices = ref.watch(pricesProvider).value ?? {};
    final t = ref.watch(tValueProvider).value ?? 0.0;
    final marginStatus = ref.watch(marginStatusProvider);
    final rollingVols = ref.watch(rollingVolatilityProvider);
    final stressShift = useState(0.0);

    if (marginStatus.isLiquidated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final exitPrices =
            calculateExitPrices(positions, prices, t, rollingVols);
        ref.read(portfolioProvider.notifier).closeAllPositions(exitPrices);
        ref.read(tradeHistoryProvider.notifier).refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('LIQUIDATION: All positions force-closed'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      });
    }

    double netDelta = 0, netGamma = 0, netVega = 0, netTheta = 0;
    double stressedPnL = 0;

    for (final pos in positions) {
      if (!pos.isFilled) continue;
      final spot = prices[pos.symbol] ?? 0.0;
      if (spot == 0) continue;

      final baseVol = rollingVols[pos.symbol] ?? 0.50;
      final iv = VolatilityEngine(baseVolatility: baseVol).calculateIV(
        S: spot, K: pos.strike, T: t,
      );

      final res = BlackScholesEngine.calculate(
        S: spot, K: pos.strike, T: t, r: 0.05, v: iv,
        type: pos.type == 'call' ? OptionType.call : OptionType.put,
      );

      netDelta += res.delta * pos.quantity;
      netGamma += res.gamma * pos.quantity;
      netVega += res.vega * pos.quantity;
      netTheta += res.theta * pos.quantity;

      if (stressShift.value != 0) {
        final stressedSpot = spot * (1 + stressShift.value / 100);
        final stressedRes = BlackScholesEngine.calculate(
          S: stressedSpot, K: pos.strike, T: t, r: 0.05, v: iv,
          type: pos.type == 'call' ? OptionType.call : OptionType.put,
        );
        stressedPnL +=
            (stressedRes.premium - pos.entryPrice) * pos.quantity;
      }
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Risk Management'),
          backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (marginStatus.isLiquidated)
            const Card(
              color: Colors.redAccent,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'LIQUIDATION TRIGGERED: Positions force-closed at market',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          _buildGreekCard('Net Delta (Δ)', netDelta,
              'Price sensitivity per \$1 move'),
          _buildGreekCard('Net Gamma (Γ)', netGamma,
              'Delta change rate'),
          _buildGreekCard('Net Vega (ν)', netVega,
              'Sensitivity to 1% vol change'),
          _buildGreekCard('Net Theta (Θ)', netTheta,
              'Time decay per day'),
          const SizedBox(height: 24),
          _buildStressTestCard(stressShift, stressedPnL, positions),
          const SizedBox(height: 16),
          _buildMarginCard(marginStatus),
        ],
      ),
    );
  }

  Widget _buildGreekCard(String label, double value, String desc) {
    return Card(
      color: const Color(0xFF1E2329),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(desc,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            Text(
              value.toStringAsFixed(4),
              style: TextStyle(
                color:
                    value >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressTestCard(
    ValueNotifier<double> stressShift,
    double stressedPnL,
    List<Position> positions,
  ) {
    final hasPositions = positions.any((p) => p.isFilled);

    return Card(
      color: const Color(0xFF1E2329),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stress Test',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spot Move: ${stressShift.value > 0 ? "+" : ""}${stressShift.value.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white54),
                ),
                if (hasPositions && stressShift.value != 0)
                  Text(
                    'P&L: ${stressedPnL >= 0 ? "+" : ""}\$${stressedPnL.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: stressedPnL >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            Slider(
              value: stressShift.value,
              min: -10,
              max: 10,
              divisions: 40,
              activeColor: const Color(0xFFF0B90B),
              label: '${stressShift.value.toStringAsFixed(1)}%',
              onChanged: (v) => stressShift.value = v,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('-10%',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
                TextButton(
                  onPressed: () => stressShift.value = 0,
                  child: const Text('Reset',
                      style: TextStyle(fontSize: 10)),
                ),
                const Text('+10%',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarginCard(MarginStatus status) {
    final ratio = status.maintenanceMargin == 0
        ? 0.0
        : status.maintenanceMargin / status.equity;
    final healthColor = ratio < 0.5
        ? Colors.greenAccent
        : ratio < 0.8
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Card(
      color: const Color(0xFF1E2329),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Margin Utilization',
                    style: TextStyle(color: Colors.white54)),
                Text(
                  '${(ratio * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: healthColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              color: healthColor,
              backgroundColor: Colors.white10,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Equity: \$${status.equity.toStringAsFixed(2)}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                Text(
                  'Margin: \$${status.maintenanceMargin.toStringAsFixed(2)}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
