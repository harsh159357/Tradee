import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/portfolio_state.dart';
import '../features/risk_state.dart';
import 'theme.dart';
import 'widgets/glass_card.dart';

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text(
              'Risk',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (marginStatus.isLiquidated)
              _buildLiquidationBanner(),
            _buildGreeksGrid(greeks),
            const SizedBox(height: 16),
            _buildMarginGauge(marginStatus),
            const SizedBox(height: 16),
            _buildStressTest(context, stressShift, stressedPnL, positions),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lossDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.loss.withAlpha(80)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.loss, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIQUIDATION TRIGGERED',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.loss,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All positions have been force-closed at market',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeksGrid(NetGreeks greeks) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _GreekCard(symbol: 'Δ', name: 'Delta', value: greeks.delta, desc: 'Price sensitivity'),
        _GreekCard(symbol: 'Γ', name: 'Gamma', value: greeks.gamma, desc: 'Delta change rate'),
        _GreekCard(symbol: 'ν', name: 'Vega', value: greeks.vega, desc: 'Vol sensitivity'),
        _GreekCard(symbol: 'Θ', name: 'Theta', value: greeks.theta, desc: 'Time decay / day'),
      ],
    );
  }

  Widget _buildMarginGauge(MarginStatus status) {
    final ratio = status.equity > 0
        ? (status.maintenanceMargin / status.equity).clamp(0.0, 1.0)
        : 0.0;
    final healthColor = ratio < 0.5
        ? AppColors.profit
        : ratio < 0.8
            ? Colors.orange
            : AppColors.loss;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Margin Health',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(ratio * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: healthColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _GaugePainter(value: ratio, color: healthColor),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${status.maintenanceMargin.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'of \$${status.equity.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GaugeLegend(label: 'Equity', value: '\$${status.equity.toStringAsFixed(2)}'),
              _GaugeLegend(label: 'Used', value: '\$${status.maintenanceMargin.toStringAsFixed(2)}'),
              _GaugeLegend(
                label: 'Available',
                value: '\$${status.availableMargin.toStringAsFixed(2)}',
                color: status.availableMargin < 0 ? AppColors.loss : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStressTest(BuildContext context, ValueNotifier<double> stressShift,
      double stressedPnL, List<Position> positions) {
    final hasPositions = positions.any((p) => p.isFilled);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stress Test',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
              ),
              if (hasPositions && stressShift.value != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stressedPnL >= 0 ? AppColors.profitDim : AppColors.lossDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${stressedPnL >= 0 ? "+" : ""}\$${stressedPnL.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: stressedPnL >= 0 ? AppColors.profit : AppColors.loss,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${stressShift.value > 0 ? "+" : ""}${stressShift.value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: stressShift.value == 0
                    ? AppColors.textTertiary
                    : stressShift.value > 0
                        ? AppColors.profit
                        : AppColors.loss,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Slider(
            value: stressShift.value,
            min: -10,
            max: 10,
            divisions: 40,
            label: '${stressShift.value.toStringAsFixed(1)}%',
            onChanged: (v) => stressShift.value = v,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('-10%', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              TextButton(
                onPressed: () => stressShift.value = 0,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 28),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
              const Text('+10%', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreekCard extends StatelessWidget {
  final String symbol;
  final String name;
  final double value;
  final String desc;

  const _GreekCard({
    required this.symbol,
    required this.name,
    required this.value,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final color = value >= 0 ? AppColors.profit : AppColors.loss;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toStringAsFixed(4),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugeLegend extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _GaugeLegend({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: color ?? AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = 2.3;
    const sweepAngle = 4.0;

    final bgPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value.clamp(0.0, 1.0),
      false,
      fgPaint,
    );

    final thumbAngle = startAngle + sweepAngle * value.clamp(0.0, 1.0);
    final thumbX = center.dx + radius * math.cos(thumbAngle);
    final thumbY = center.dy + radius * math.sin(thumbAngle);
    canvas.drawCircle(
      Offset(thumbX, thumbY),
      6,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(thumbX, thumbY),
      3,
      Paint()..color = AppColors.surface,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
