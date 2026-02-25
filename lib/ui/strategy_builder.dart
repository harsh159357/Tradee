import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../features/market_state.dart';
import 'theme.dart';
import 'widgets/empty_state.dart';
import 'widgets/glass_card.dart';

class StrategyBuilderScreen extends HookConsumerWidget {
  const StrategyBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legs = useState<List<OptionContract>>([]);
    final prices = ref.watch(pricesProvider).value ?? {};
    final symbol = ref.watch(selectedAssetProvider);
    final spot = prices[symbol] ?? 0.0;

    double totalDelta = 0, totalGamma = 0, totalVega = 0, totalTheta = 0, totalPremium = 0;
    for (final leg in legs.value) {
      totalDelta += leg.greeks.delta;
      totalGamma += leg.greeks.gamma;
      totalVega += leg.greeks.vega;
      totalTheta += leg.greeks.theta;
      totalPremium += leg.greeks.premium;
    }

    double maxProfit = double.negativeInfinity;
    double maxLoss = double.infinity;
    if (legs.value.isNotEmpty && spot > 0) {
      final startPrice = spot * AppConstants.chartRangeMin;
      final endPrice = spot * AppConstants.chartRangeMax;
      for (int i = 0; i <= 200; i++) {
        final s = startPrice + (endPrice - startPrice) * i / 200;
        double pnl = 0;
        for (final leg in legs.value) {
          final intrinsic = leg.type == OptionType.call
              ? (s > leg.strike ? s - leg.strike : 0.0)
              : (leg.strike > s ? leg.strike - s : 0.0);
          pnl += intrinsic - leg.greeks.premium;
        }
        if (pnl > maxProfit) maxProfit = pnl;
        if (pnl < maxLoss) maxLoss = pnl;
      }
    } else {
      maxProfit = 0;
      maxLoss = 0;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Strategy',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (legs.value.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textTertiary),
                      onPressed: () => legs.value = [],
                      tooltip: 'Clear all legs',
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _buildSummaryCard(context, totalPremium, totalDelta, totalGamma, totalVega, totalTheta, maxProfit, maxLoss),
                  if (legs.value.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payoff at Expiry',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                painter: PayoffChartPainter(
                                  legs: legs.value,
                                  currentSpot: spot,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...legs.value.asMap().entries.map((entry) {
                      final i = entry.key;
                      final leg = entry.value;
                      final isCall = leg.type == OptionType.call;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (isCall ? AppColors.profitDim : AppColors.lossDim),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isCall ? Icons.trending_up : Icons.trending_down,
                                  size: 16,
                                  color: isCall ? AppColors.profit : AppColors.loss,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${leg.type.name.toUpperCase()} ${leg.strike.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    Text(
                                      '\$${leg.greeks.premium.toStringAsFixed(2)}  ·  Δ ${leg.greeks.delta.toStringAsFixed(2)}',
                                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                                onPressed: () {
                                  final newList = List<OptionContract>.from(legs.value);
                                  newList.removeAt(i);
                                  legs.value = newList;
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surfaceLight,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  if (legs.value.isEmpty)
                    const SizedBox(
                      height: 240,
                      child: EmptyState(
                        icon: Icons.hub_outlined,
                        message: 'Build Multi-Leg Strategies',
                        subtitle: 'Add option legs to visualize payoff',
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddLegSelector(context, ref, legs),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('ADD LEG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double premium, double d, double g, double v, double t,
    double maxProfit, double maxLoss,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Premium', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              Text(
                '\$${premium.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.profitDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('Max Profit', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        _boundedValue(maxProfit),
                        style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lossDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('Max Loss', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        _boundedValue(maxLoss),
                        style: const TextStyle(color: AppColors.loss, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GreekChip('Δ', d),
              _GreekChip('Γ', g),
              _GreekChip('ν', v),
              _GreekChip('Θ', t),
            ],
          ),
        ],
      ),
    );
  }

  String _boundedValue(double v) {
    if (v == double.infinity || v == double.negativeInfinity) return '—';
    return '\$${v.toStringAsFixed(2)}';
  }

  void _showAddLegSelector(BuildContext context, WidgetRef ref, ValueNotifier<List<OptionContract>> legs) {
    final chain = ref.read(optionsChainProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder),
            left: BorderSide(color: AppColors.surfaceBorder),
            right: BorderSide(color: AppColors.surfaceBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Contract',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: chain.length,
                itemBuilder: (context, index) {
                  final contract = chain[index];
                  final isCall = contract.type == OptionType.call;
                  final accent = isCall ? AppColors.profit : AppColors.loss;

                  return ListTile(
                    leading: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCall ? Icons.trending_up : Icons.trending_down,
                        size: 16, color: accent,
                      ),
                    ),
                    title: Text(
                      '${contract.type.name.toUpperCase()} ${contract.strike.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    trailing: Text(
                      '\$${contract.greeks.premium.toStringAsFixed(2)}',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      legs.value = [...legs.value, contract];
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreekChip extends StatelessWidget {
  final String label;
  final double val;

  const _GreekChip(this.label, this.val);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            val.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class PayoffChartPainter extends CustomPainter {
  final List<OptionContract> legs;
  final double currentSpot;

  PayoffChartPainter({required this.legs, required this.currentSpot});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentSpot == 0 || legs.isEmpty) return;

    final chartLeft = 40.0;
    final chartBottom = 24.0;
    final chartWidth = size.width - chartLeft - 12;
    final chartHeight = size.height - chartBottom - 8;

    final startPrice = currentSpot * AppConstants.chartPayoffRangeMin;
    final endPrice = currentSpot * AppConstants.chartPayoffRangeMax;
    final priceRange = endPrice - startPrice;

    double maxPnL = -double.infinity;
    double minPnL = double.infinity;
    final points = <Offset>[];
    const steps = 80;

    for (int i = 0; i <= steps; i++) {
      final s = startPrice + (priceRange * i / steps);
      double totalPnL = 0;
      for (final leg in legs) {
        final intrinsic = leg.type == OptionType.call
            ? (s > leg.strike ? s - leg.strike : 0.0)
            : (leg.strike > s ? leg.strike - s : 0.0);
        totalPnL += intrinsic - leg.greeks.premium;
      }
      if (totalPnL > maxPnL) maxPnL = totalPnL;
      if (totalPnL < minPnL) minPnL = totalPnL;
      points.add(Offset(s, totalPnL));
    }

    final yBound = [maxPnL.abs(), minPnL.abs()].reduce((a, b) => a > b ? a : b);
    final yMax = yBound > 0 ? yBound * 1.2 : 100.0;

    double getX(double price) => chartLeft + (price - startPrice) / priceRange * chartWidth;
    double getY(double pnl) => 8 + (chartHeight / 2) - (pnl / yMax * (chartHeight / 2));

    final gridPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..strokeWidth = 0.5;

    final zeroY = getY(0);
    canvas.drawLine(Offset(chartLeft, zeroY), Offset(chartLeft + chartWidth, zeroY), gridPaint);

    final spotX = getX(currentSpot);
    final dashPaint = Paint()
      ..color = AppColors.textTertiary.withAlpha(60)
      ..strokeWidth = 1;
    for (double dy = 8.0; dy < size.height - chartBottom; dy += 6) {
      canvas.drawLine(Offset(spotX, dy), Offset(spotX, dy + 3), dashPaint);
    }

    final path = Path();
    final profitPath = Path();
    final lossPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = getX(points[i].dx);
      final y = getY(points[i].dy);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    for (int i = 0; i < points.length; i++) {
      final x = getX(points[i].dx);
      final pnl = points[i].dy;
      final y = getY(pnl);
      if (pnl >= 0) {
        if (i == 0 || points[i - 1].dy < 0) {
          profitPath.moveTo(x, zeroY);
          profitPath.lineTo(x, y);
        } else {
          profitPath.lineTo(x, y);
        }
        if (i == points.length - 1 || points[i + 1].dy < 0) {
          profitPath.lineTo(x, zeroY);
          profitPath.close();
        }
      } else {
        if (i == 0 || points[i - 1].dy >= 0) {
          lossPath.moveTo(x, zeroY);
          lossPath.lineTo(x, y);
        } else {
          lossPath.lineTo(x, y);
        }
        if (i == points.length - 1 || points[i + 1].dy >= 0) {
          lossPath.lineTo(x, zeroY);
          lossPath.close();
        }
      }
    }

    canvas.drawPath(
      profitPath,
      Paint()..color = AppColors.profit.withAlpha(30),
    );
    canvas.drawPath(
      lossPath,
      Paint()..color = AppColors.loss.withAlpha(30),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final currentPnL = _pnlAt(currentSpot);
    canvas.drawCircle(
      Offset(spotX, getY(currentPnL)),
      5,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      Offset(spotX, getY(currentPnL)),
      2.5,
      Paint()..color = AppColors.surface,
    );

    final labelStyle = ui.TextStyle(
      color: AppColors.textTertiary,
      fontSize: 10,
    );

    _drawLabel(canvas, startPrice.toStringAsFixed(0), Offset(chartLeft, size.height - 14), labelStyle);
    _drawLabel(canvas, currentSpot.toStringAsFixed(0), Offset(spotX - 14, size.height - 14), labelStyle);
    _drawLabel(canvas, endPrice.toStringAsFixed(0), Offset(chartLeft + chartWidth - 24, size.height - 14), labelStyle);

    _drawLabel(canvas, '+${yMax.toStringAsFixed(0)}', Offset(2, 6), labelStyle);
    _drawLabel(canvas, '0', Offset(18, zeroY - 6), labelStyle);
    _drawLabel(canvas, '-${yMax.toStringAsFixed(0)}', Offset(2, chartHeight - 2), labelStyle);
  }

  double _pnlAt(double s) {
    double total = 0;
    for (final leg in legs) {
      final intrinsic = leg.type == OptionType.call
          ? (s > leg.strike ? s - leg.strike : 0.0)
          : (leg.strike > s ? leg.strike - s : 0.0);
      total += intrinsic - leg.greeks.premium;
    }
    return total;
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, ui.TextStyle style) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.left))
      ..pushStyle(style)
      ..addText(text);
    final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 60));
    canvas.drawParagraph(paragraph, offset);
  }

  @override
  bool shouldRepaint(covariant PayoffChartPainter old) => true;
}
