import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'market_state.dart';
import 'portfolio_state.dart';
import '../engines/pricing_engine.dart';
import '../engines/margin_engine.dart';

class MarginStatus {
  final double equity;
  final double maintenanceMargin;
  final bool isLiquidated;

  MarginStatus({
    required this.equity,
    required this.maintenanceMargin,
    required this.isLiquidated,
  });
}

final marginStatusProvider = Provider<MarginStatus>((ref) {
  final balance = ref.watch(balanceProvider);
  final positions = ref.watch(portfolioProvider);
  final prices = ref.watch(pricesProvider).value ?? {};
  final t = ref.watch(tValueProvider).value ?? 0.0;

  double totalUnrealizedPnL = 0;
  double totalMarginRequired = 0;

  for (final pos in positions) {
    if (!pos.isFilled) continue;

    final spot = prices[pos.symbol] ?? 0.0;
    if (spot == 0) continue;

    // Use Black-Scholes to get current premium
    final currentRes = BlackScholesEngine.calculate(
      S: spot,
      K: pos.strike,
      T: t,
      r: 0.05,
      v: 0.50, // Simplified for now, in a real app would use per-strike IV
      type: pos.type == 'call' ? OptionType.call : OptionType.put,
    );

    // Unrealized PnL: (Current Price - Entry Price) * Quantity
    totalUnrealizedPnL += (currentRes.premium - pos.entryPrice) * pos.quantity;

    // Margin Required
    if (pos.quantity > 0) {
      // Long: Margin = premium paid (already deducted from balance usually, 
      // but here we keep balance as starting cash and equity = balance + pnl)
      totalMarginRequired += currentRes.premium * pos.quantity;
    } else {
      // Short: Margin = stress test
      totalMarginRequired += MarginEngine.calculateShortMargin(
        S: spot,
        K: pos.strike,
        T: t,
        r: 0.05,
        v: 0.50,
        type: pos.type == 'call' ? OptionType.call : OptionType.put,
        quantity: pos.quantity.abs(),
      );
    }
  }

  final equity = balance + totalUnrealizedPnL;
  final isLiquidated = equity < totalMarginRequired && positions.any((p) => p.isFilled);

  // Auto-liquidation trigger
  if (isLiquidated) {
    // In a real execution, we would call a liquidation method on the notifier
    // But providers should be pure. We'll handle side-effects in a listener.
  }

  return MarginStatus(
    equity: equity,
    maintenanceMargin: totalMarginRequired,
    isLiquidated: isLiquidated,
  );
});
