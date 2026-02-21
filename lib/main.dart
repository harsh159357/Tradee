import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'data/storage_service.dart';
import 'features/market_state.dart';
import 'features/portfolio_state.dart';
import 'features/risk_state.dart';
import 'ui/theme.dart';
import 'ui/navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const ProviderScope(child: TradeeApp()));
}

class TradeeApp extends ConsumerStatefulWidget {
  const TradeeApp({super.key});

  @override
  ConsumerState<TradeeApp> createState() => _TradeeAppState();
}

class _TradeeAppState extends ConsumerState<TradeeApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _liquidationHandled = false;
  bool _expiryHandled = false;

  @override
  void initState() {
    super.initState();

    // Listen for liquidation events
    ref.listenManual(marginStatusProvider, (prev, next) {
      if (next.isLiquidated && !_liquidationHandled) {
        _liquidationHandled = true;
        _handleLiquidation();
      } else if (!next.isLiquidated) {
        _liquidationHandled = false;
      }
    });

    // Listen for expiry (T hits 0 while app is open)
    ref.listenManual(tValueProvider, (prev, next) {
      final t = next.value;
      if (t != null && t <= 0 && !_expiryHandled) {
        _expiryHandled = true;
        _handleExpiry();
      }
    });
  }

  void _handleLiquidation() {
    final positions = ref.read(portfolioProvider);
    final prices = ref.read(pricesProvider).value ?? {};
    final t = ref.read(tValueProvider).value ?? 0.0;
    final rollingVols = ref.read(rollingVolatilityProvider);

    final exitPrices = calculateExitPrices(positions, prices, t, rollingVols);
    ref.read(portfolioProvider.notifier).closeAllPositions(exitPrices);
    ref.read(tradeHistoryProvider.notifier).refresh();

    _showSnackBar('LIQUIDATION: All positions force-closed at market',
        Colors.redAccent);
  }

  void _handleExpiry() {
    final positions = ref.read(portfolioProvider);
    if (positions.isEmpty) return;

    final prices = ref.read(pricesProvider).value ?? {};
    final rollingVols = ref.read(rollingVolatilityProvider);

    // At expiry T=0, BS returns intrinsic value
    final exitPrices = calculateExitPrices(positions, prices, 0.0, rollingVols);
    ref.read(portfolioProvider.notifier).closeAllPositions(exitPrices);
    ref.read(tradeHistoryProvider.notifier).refresh();

    _showSnackBar('EXPIRY: All positions settled at intrinsic value',
        const Color(0xFFF0B90B));
  }

  void _showSnackBar(String message, Color color) {
    final ctx = _navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Tradee',
      theme: AppTheme.darkTheme,
      home: const MainNavigationWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
