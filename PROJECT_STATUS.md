# Tradee - Project Status

**Last updated:** 2026-02-21
**Overall completion:** ~99%
**Build status:** Compiles and runs on Android
**Git tag:** Tradee_V1

---

## Spec Coverage by Section

| Section | Title | Status |
|---------|-------|--------|
| 2 | Core Constraints | 100% |
| 3 | Architecture | 100% -- `core/`, `domain/`, `data/`, `engines/`, `features/`, `ui/` |
| 4 | Market Data | 95% -- field testing pending |
| 5 | Time Engine | 100% |
| 6 | Options Generation | 100% |
| 7 | Pricing Engine | 100% |
| 8 | Volatility Engine | 100% |
| 9 | Order Simulation | 100% |
| 10 | Portfolio Engine | 100% -- includes limit order margin hold |
| 11 | Risk Engine | 100% -- liquidation at worst bid/ask |
| 12 | Screens | 100% -- 24h %, confirmation dialog, IST display |
| 13 | Local Storage | 100% |
| 14 | Performance | 85% -- isolate with guard, device profiling pending |
| 15 | UI Requirements | 100% |
| 16 | Edge Cases | 100% |
| 17 | Out of Scope | N/A |
| 18 | Code Quality | 100% |
| 19 | Future Extensibility | Done -- TimeEngine param, Position.expiry, MarketDataSource interface |

---

## File Inventory

### Core (1 file)
- `core/constants.dart` -- Centralized constants

### Domain (5 files -- pure Dart, no Flutter dependency)
- `domain/position.dart` -- Position (with expiry field), TradeRecord
- `domain/price_point.dart` -- PricePoint
- `domain/option_contract.dart` -- OptionContract
- `domain/margin_status.dart` -- MarginStatus (with availableMargin)
- `domain/market_data_source.dart` -- Abstract interface for backend swapability

### Engines (5 files -- stateless, tested)
- `engines/pricing_engine.dart` -- Black-Scholes + Greeks
- `engines/time_engine.dart` -- Expiry (configurable), T calc, IST display
- `engines/volatility_engine.dart` -- IV skew, rolling realized vol
- `engines/margin_engine.dart` -- Long/short margin, stress test
- `engines/spread_engine.dart` -- Bid/ask, slippage, vol-adjusted widening

### Data Layer (2 files)
- `data/market_data_service.dart` -- WebSocket + REST + 24h change API, implements MarketDataSource
- `data/storage_service.dart` -- Hive init, daily reset

### State Management (3 files)
- `features/market_state.dart` -- Prices, chain (isolate-guarded FutureProvider), 24h change, limit fills
- `features/portfolio_state.dart` -- Portfolio/balance/history notifiers
- `features/risk_state.dart` -- Margin status, exit at worst bid/ask

### UI (9 files)
- `ui/asset_selection_screen.dart` -- 24h % from Binance, expiry in IST
- `ui/trading_screen.dart` -- Expiry countdown + IST label
- `ui/trade_bottom_sheet.dart` -- Confirmation dialog, limit margin hold
- `ui/portfolio_screen.dart` -- Used/Available margin rows, limit refund
- `ui/risk_dashboard.dart` -- Greeks, stress test, margin bar
- `ui/strategy_builder.dart` -- Payoff chart, max P/L
- `ui/settings_screen.dart` -- IST expiry display
- `ui/navigation_wrapper.dart`
- `ui/theme.dart`

### App Root
- `main.dart` -- Liquidation + expiry listeners

### Tests (5 files, 42 tests)
- `test/pricing_engine_test.dart` (11)
- `test/volatility_engine_test.dart` (8)
- `test/margin_engine_test.dart` (7)
- `test/spread_engine_test.dart` (8)
- `test/time_engine_test.dart` (5)

---

## What's Left (manual only)

1. **Device profiling** -- Verify 60fps on mid-range Android with DevTools.
2. **WebSocket field test** -- Stress-test reconnect on real device with flaky connectivity.

---

## Commit History

| Hash | Description |
|------|------------|
| `3a82ab0` | Initial commit |
| `c411f63` | feat: Limit orders, risk state, strategy builder, settings |
| `9b8a964` | docs: Project status report |
| `6662ce4` | feat: Price history, payoff chart, slippage, expiry reset |
| `0a095f9` | feat: Major overhaul -- WebSocket, spreads, liquidation, tests |
| `3068d59` | fix: ProviderRef type error |
| `0d24b48` | feat: In-session expiry, vol-adjusted spreads, % change, max P/L |
| `8331568` | fix: AsyncValue.value getter |
| `13f71b1` | refactor: core/ + domain/ dirs, isolate chain, limit margin hold |
| *(next)* | fix: Audit fixes -- bid/ask exit, confirmation, 24h%, IST, extensibility |
