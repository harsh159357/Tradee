import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../features/market_state.dart';
import 'widgets/empty_state.dart';

class StrategyBuilderScreen extends HookConsumerWidget {
  const StrategyBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legs = useState<List<OptionContract>>([]);
    final prices = ref.watch(pricesProvider).value ?? {};
    final symbol = ref.watch(selectedAssetProvider);
    final spot = prices[symbol] ?? 0.0;
    
    double totalDelta = 0;
    double totalGamma = 0;
    double totalVega = 0;
    double totalTheta = 0;
    double totalPremium = 0;

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
      appBar: AppBar(
        title: const Text('Strategy Builder'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => legs.value = [],
          )
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(context, totalPremium, totalDelta, totalGamma, totalVega, totalTheta, maxProfit, maxLoss),
          if (legs.value.isNotEmpty)
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: PayoffChartPainter(
                    legs: legs.value,
                    currentSpot: spot,
                    lineColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: legs.value.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: legs.value.length,
                  itemBuilder: (context, index) {
                    final leg = legs.value[index];
                    return ListTile(
                      title: Text('${leg.type.name.toUpperCase()} ${leg.strike.toStringAsFixed(0)}'),
                      subtitle: Text('Premium: \$${leg.greeks.premium.toStringAsFixed(2)} | Δ: ${leg.greeks.delta.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () {
                          final newList = List<OptionContract>.from(legs.value);
                          newList.removeAt(index);
                          legs.value = newList;
                        },
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showAddLegSelector(context, ref, legs),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('ADD LEG'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    double premium, double d, double g, double v, double t,
    double maxProfit, double maxLoss,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Cost/Credit', style: TextStyle(color: Colors.white54)),
              Text('\$${premium.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Max Profit: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(
                    maxProfit == double.infinity || maxProfit == double.negativeInfinity
                        ? '—'
                        : '\$${maxProfit.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Max Loss: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(
                    maxLoss == double.infinity || maxLoss == double.negativeInfinity
                        ? '—'
                        : '\$${maxLoss.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _greekMini('Δ', d),
              _greekMini('Γ', g),
              _greekMini('V', v),
              _greekMini('Θ', t),
            ],
          )
        ],
      ),
    );
  }

  Widget _greekMini(String label, double val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        Text(val.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.architecture,
      message: 'Build Multi-leg Strategies',
    );
  }

  void _showAddLegSelector(BuildContext context, WidgetRef ref, ValueNotifier<List<OptionContract>> legs) {
    final chain = ref.read(optionsChainProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ListView.builder(
        itemCount: chain.length,
        itemBuilder: (context, index) {
          final contract = chain[index];
          return ListTile(
            title: Text('${contract.type.name.toUpperCase()} ${contract.strike.toStringAsFixed(0)}'),
            trailing: Text('\$${contract.greeks.premium.toStringAsFixed(2)}'),
            onTap: () {
              legs.value = [...legs.value, contract];
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

class PayoffChartPainter extends CustomPainter {
  final List<OptionContract> legs;
  final double currentSpot;
  final Color lineColor;

  PayoffChartPainter({required this.legs, required this.currentSpot, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentSpot == 0) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..style = PaintingStyle.fill;

    final paintAxis = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    // Range: +/- 10% of current spot
    final startPrice = currentSpot * AppConstants.chartPayoffRangeMin;
    final endPrice = currentSpot * AppConstants.chartPayoffRangeMax;
    final priceRange = endPrice - startPrice;

    double maxPnL = -double.infinity;
    double minPnL = double.infinity;

    final points = <Offset>[];
    const steps = 50;
    
    for (int i = 0; i <= steps; i++) {
      final s = startPrice + (priceRange * i / steps);
      double totalPnL = 0;
      for (final leg in legs) {
        // PnL at expiry: intrinsic value - premium paid
        final intrinsic = leg.type == OptionType.call 
            ? (s > leg.strike ? s - leg.strike : 0.0)
            : (leg.strike > s ? leg.strike - s : 0.0);
        totalPnL += intrinsic - leg.greeks.premium;
      }
      if (totalPnL > maxPnL) maxPnL = totalPnL;
      if (totalPnL < minPnL) minPnL = totalPnL;
      points.add(Offset(s, totalPnL));
    }

    // Normalize Y axis
    final yBound = [maxPnL.abs(), minPnL.abs()].reduce((a, b) => a > b ? a : b);
    final yMax = yBound > 0 ? yBound * 1.2 : 100.0;

    double getY(double pnl) {
      // 0 pnl is at size.height / 2
      return (size.height / 2) - (pnl / yMax * (size.height / 2));
    }

    double getX(double price) {
      return (price - startPrice) / priceRange * size.width;
    }

    // Draw grid
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paintAxis);
    canvas.drawLine(Offset(getX(currentSpot), 0), Offset(getX(currentSpot), size.height), paintAxis..color = Colors.blue.withAlpha(77));

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = getX(points[i].dx);
      final y = getY(points[i].dy);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw fill area below/above 0
    final fillPath = Path.from(path);
    fillPath.lineTo(getX(endPrice), size.height / 2);
    fillPath.lineTo(getX(startPrice), size.height / 2);
    fillPath.close();
    
    paintFill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.green.withAlpha(51), Colors.red.withAlpha(51)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Current price dot
    canvas.drawCircle(Offset(getX(currentSpot), getY(_calculatePnLAt(currentSpot))), 4, Paint()..color = Colors.white);
  }

  double _calculatePnLAt(double s) {
    double totalPnL = 0;
    for (final leg in legs) {
      final intrinsic = leg.type == OptionType.call 
          ? (s > leg.strike ? s - leg.strike : 0.0)
          : (leg.strike > s ? leg.strike - s : 0.0);
      totalPnL += intrinsic - leg.greeks.premium;
    }
    return totalPnL;
  }

  @override
  bool shouldRepaint(covariant PayoffChartPainter oldDelegate) => true;
}
