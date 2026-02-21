import '../engines/pricing_engine.dart';
import '../engines/spread_engine.dart';

class OptionContract {
  final double strike;
  final OptionType type;
  final BlackScholesResult greeks;
  final double iv;
  final SpreadResult spread;

  OptionContract({
    required this.strike,
    required this.type,
    required this.greeks,
    required this.iv,
    required this.spread,
  });
}
