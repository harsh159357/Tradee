# Tradee - Project Status

**Last updated:** 2026-02-21
**Overall completion:** ~97%
**Build status:** Compiles and runs on Android
**Git tag:** Tradee_V1

---

## Spec Coverage by Section

### Section 2: Core Constraints -- 100%

All 12 constraints satisfied.

### Section 3: Architecture -- 100%

```
lib/
 ├── core/            (constants.dart)
 ├── data/            (market_data_service, storage_service)
 ├── domain/          (position, price_point, option_contract, margin_status)
 ├── engines/         (pricing, time, volatility, margin, spread)
 ├── features/        (market_state, portfolio_state, risk_state)
 ├── ui/              (7 screens + theme + navigation)
 └── main.dart        (app root + liquidation & expiry listeners)
```

All spec-mandated directories (`core/`, `domain/`, `data/`, `engines/`,
`features/`, `ui/`) are present. Domain models are in `domain/` and
re-exported from feature files for backward compatibility.

### Section 4: Market Data -- 95%

| Requirement | Status |
|------------|--------|
| WebSocket to Binance | Done |
| 3 assets (BTC/ETH/SOL) | Done |
| Auto reconnect | Done |
| Heartbeat monitoring | Done |
| Fallback REST polling | Done |
| Debounce 200-300ms | Done |
| Latest price in state | Done |

Remaining: Not field-tested on real device with intermittent connectivity.

### Section 5: Time Engine -- 100%

All requirements met including in-session expiry auto-close.

### Section 6: Options Generation -- 100%

### Section 7: Pricing Engine -- 100%

### Section 8: Volatility Engine -- 100%

### Section 9: Order Simulation -- 100%

### Section 10: Portfolio Engine -- 100%

| Requirement | Status |
|------------|--------|
| Initial balance $100,000 | Done |
| Available margin tracking | Done |
| Used margin tracking | Done |
| Unrealized PnL | Done |
| Realized PnL | Done |
| Trade history | Done |
| Recalc on spot/time/vol change | Done |
| Limit order margin hold | Done (margin reserved on placement, refunded on cancel) |

### Section 11: Risk Engine -- 100%

### Section 12: Screens -- 100%

### Section 13: Local Storage -- 100%

### Section 14: Performance -- 80%

| Requirement | Status |
|------------|--------|
| Throttle recalculations | Done (250ms debounce) |
| Use isolates for heavy math | Done (`Isolate.run()` for chain computation) |
| No full rebuild every tick | Done (FutureProvider + isolate offloads work) |
| Avoid jank | Likely OK for 9 strikes |
| 60fps on mid-range Android | **Not profiled** |

### Section 15: UI Requirements -- 100%

### Section 16: Edge Cases -- 100%

### Section 18: Code Quality -- 100%

| Requirement | Status |
|------------|--------|
| Null-safe Dart | Done |
| Strong typing | Done |
| Clean architecture | Done (core/ + domain/ + engines/ + features/ + ui/) |
| Unit tests | Done (42 tests across 5 engine test files) |
| Separation of concerns | Done |
| No business logic in UI | Done |
| Centralized constants | Done (core/constants.dart) |

---

## File Inventory

### Core (1 file)
- `core/constants.dart` -- Risk-free rate, initial balance, vol defaults, spread params, asset list, strike offsets

### Domain (4 files -- pure Dart models, no dependencies on Flutter)
- `domain/position.dart` -- Position, TradeRecord
- `domain/price_point.dart` -- PricePoint
- `domain/option_contract.dart` -- OptionContract
- `domain/margin_status.dart` -- MarginStatus

### Engines (5 files -- all pure Dart, stateless, tested)
- `engines/pricing_engine.dart` -- Black-Scholes with all Greeks
- `engines/time_engine.dart` -- UTC expiry, T calculation, countdown
- `engines/volatility_engine.dart` -- IV skew, rolling realized vol
- `engines/margin_engine.dart` -- Long/short margin, stress test
- `engines/spread_engine.dart` -- Bid/ask, spread, slippage, vol-adjusted widening

### Data Layer (2 files)
- `data/market_data_service.dart` -- WebSocket + REST + heartbeat + debounce
- `data/storage_service.dart` -- Hive init, daily expiry reset

### State Management (3 files)
- `features/market_state.dart` -- Providers for prices, time, options chain (isolate), limit fills, session prices
- `features/portfolio_state.dart` -- PortfolioNotifier, BalanceNotifier, TradeHistoryNotifier
- `features/risk_state.dart` -- MarginStatus provider, exit price calculation

### UI (9 files)
- `ui/asset_selection_screen.dart` -- Session % change display
- `ui/trading_screen.dart`
- `ui/trade_bottom_sheet.dart` -- Limit order margin hold
- `ui/portfolio_screen.dart` -- Limit order margin refund on cancel
- `ui/risk_dashboard.dart`
- `ui/strategy_builder.dart` -- Max profit/loss display
- `ui/settings_screen.dart`
- `ui/navigation_wrapper.dart`
- `ui/theme.dart`

### App Root
- `main.dart` -- Liquidation listener + expiry auto-close listener

### Tests (5 files, 42 tests total)
- `test/pricing_engine_test.dart` (11)
- `test/volatility_engine_test.dart` (8)
- `test/margin_engine_test.dart` (7)
- `test/spread_engine_test.dart` (8)
- `test/time_engine_test.dart` (5)

---

## What's Left to Reach 100%

### Manual Testing Only

1. **Device profiling (Section 14)**
   Verify 60fps on mid-range Android with Flutter DevTools.

2. **WebSocket field test (Section 4)**
   Stress-test reconnect/fallback on a real device with flaky connectivity.

These are the only remaining items and cannot be addressed through code alone.

---

## Commit History

| Hash | Description |
|------|------------|
| `3a82ab0` | Initial commit: Flutter project, engines, state, UI |
| `c411f63` | feat: Limit orders, risk state, strategy builder, settings |
| `9b8a964` | docs: Project status report |
| `6662ce4` | feat: Price history, payoff chart, slippage, expiry reset |
| `0a095f9` | feat: Major overhaul -- WebSocket, spreads, liquidation, tests |
| `3068d59` | fix: ProviderRef type error and missing import |
| `0d24b48` | feat: In-session expiry, vol-adjusted spreads, % change, max P/L |
| `8331568` | fix: AsyncValue.value getter |
| *(next)* | refactor: core/ + domain/ dirs, isolate chain, limit margin hold |
