import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/risk_state.dart';

class RiskDashboard extends HookConsumerWidget {
  const RiskDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeks = ref.watch(netGreeksProvider);
    final marginStatus = ref.watch(marginStatusProvider);
    final positions = ref.watch(portfolioProvider);
    final stressShift = useState(0.0);
    final stressedPnL = ref.watch(stressedPnLProvider(stressShift.value));

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
          _buildGreekCard(context, 'Net Delta (Δ)', greeks.delta,
              'Price sensitivity per \$1 move'),
          _buildGreekCard(context, 'Net Gamma (Γ)', greeks.gamma,
              'Delta change rate'),
          _buildGreekCard(context, 'Net Vega (ν)', greeks.vega,
              'Sensitivity to 1% vol change'),
          _buildGreekCard(context, 'Net Theta (Θ)', greeks.theta,
              'Time decay per day'),
          const SizedBox(height: 24),
          _buildStressTestCard(context, stressShift, stressedPnL, positions),
          const SizedBox(height: 16),
          _buildMarginCard(context, marginStatus),
        ],
      ),
    );
  }

  Widget _buildGreekCard(BuildContext context, String label, double value, String desc) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
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
    BuildContext context,
    ValueNotifier<double> stressShift,
    double stressedPnL,
    List<Position> positions,
  ) {
    final hasPositions = positions.any((p) => p.isFilled);

    return Card(
      color: Theme.of(context).colorScheme.surface,
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
              activeColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildMarginCard(BuildContext context, MarginStatus status) {
    final ratio = status.maintenanceMargin == 0
        ? 0.0
        : status.maintenanceMargin / status.equity;
    final healthColor = ratio < 0.5
        ? Colors.greenAccent
        : ratio < 0.8
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Card(
      color: Theme.of(context).colorScheme.surface,
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
