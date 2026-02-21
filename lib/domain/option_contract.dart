import '../engines/pricing_engine.dart';
import '../engines/spread_engine.dart';

export '../domain/enums.dart';

class OptionContract {
  final double strike;
  final OptionType type;
  final BlackScholesResult greeks;
  final double iv;
  final SpreadResult spread;

  const OptionContract({
    required this.strike,
    required this.type,
    required this.greeks,
    required this.iv,
    required this.spread,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionContract &&
          strike == other.strike &&
          type == other.type;

  @override
  int get hashCode => Object.hash(strike, type);
}
