# Tradee - Project Status

**Last updated:** 2026-02-21
**Overall completion:** ~85%
**Build status:** Compiles and runs on Android

---

## Spec Coverage by Section

### Section 2: Core Constraints -- 100%

All 12 constraints satisfied:

| # | Constraint | Status |
|---|-----------|--------|
| 1 | Flutter mobile only (iOS + Android) | Done |
| 2 | Dart only | Done |
| 3 | No backend | Done |
| 4 | No Firebase | Done |
| 5 | No authentication | Done |
| 6 | Real-time spot price APIs (WebSocket) | Done |
| 7 | Only daily expiry | Done |
| 8 | Only current day expiry | Done |
| 9 | Expiry time = 23:59:59 UTC | Done |
| 10 | European options | Done |
| 11 | Black-Scholes pricing model | Done |
| 12 | Local persistence (Hive) | Done |

### Section 3: Architecture -- 90%

```
lib/
 ├── data/           (market_data_service, storage_service)
 ├── engines/         (pricing, time, volatility, margin, spread)
 ├── features/        (market_state, portfolio_state, risk_state)
 ├── ui/              (7 screens + theme + navigation)
 └── main.dart
```

Missing: `core/` and `domain/` directories from spec. Currently no domain
models separate from feature state. Low priority -- current structure works
and is clean.

### Section 4: Market Data -- 95%

| Requirement | Status | File |
|------------|--------|------|
| WebSocket to Binance | Done | `market_data_service.dart` |
| 3 assets (BTC/ETH/SOL) | Done | hardcoded in service |
| Auto reconnect | Done | 5s retry on error/close |
| Heartbeat monitoring | Done | 15s interval, 30s timeout |
| Fallback REST polling | Done | 10s interval via `http` |
| Debounce 200-300ms | Done | 250ms debounce timer |
| Latest price in state | Done | `pricesProvider` stream |

Remaining: Not field-tested on real device with intermittent connectivity.

### Section 5: Time Engine -- 95%

| Requirement | Status |
|------------|--------|
| T = (expiry - now) / seconds_in_year | Done |
| Expiry = today 23:59:59 UTC | Done |
| Update every second | Done (Stream.periodic) |
| Stream updates | Done (tValueProvider) |
| Re-price options on time change | Done (optionsChainProvider watches tValueProvider) |
| T <= 0: intrinsic value | Done (BlackScholesEngine handles T <= 0) |
| T <= 0: auto close positions | **Partial** -- positions reset on next app launch via StorageService, but no in-session auto-close when clock hits midnight |

### Section 6: Options Generation -- 100%

| Requirement | Status |
|------------|--------|
| Dynamic strikes around ATM | Done (S * [0.95, 0.97, 0.98, 0.99, 1.0, 1.01, 1.02, 1.03, 1.05]) |
| ~9-11 strikes | Done (9 strikes) |
| Call + Put per strike | Done |
| Smart rounding (BTC/100, ETH/10, SOL/1) | Done |
| Daily expiry only | Done |

### Section 7: Pricing Engine -- 100%

| Requirement | Status |
|------------|--------|
| Black-Scholes European | Done |
| Outputs: Premium, Delta, Gamma, Vega, Theta | Done |
| T < threshold: intrinsic only | Done |
| Stateless, pure Dart, deterministic | Done |
| Unit-testable | Done (11 tests) |
| Put-call parity holds | Verified in tests |

### Section 8: Volatility Engine -- 100%

| Requirement | Status |
|------------|--------|
| Rolling realized vol (1h window) | Done (PricePoint history, 60m pruning) |
| Configurable constant fallback | Done (baseVolatility = 0.50) |
| OTM puts: higher IV | Done (skew = (1 - moneyness) * 0.5) |
| OTM calls: slightly lower IV | Done (skew = (1 - moneyness) * 0.1) |
| Vol increases as T -> 0 (optional) | Done (1.2x when T < 0.01) |
| Settings toggle: rolling vs fixed | Done (volatilityModeProvider) |

### Section 9: Order Simulation -- 100%

| Requirement | Status |
|------------|--------|
| Market orders | Done (instant fill at ask/bid) |
| Limit orders | Done (fill when premium crosses) |
| Mid price = BS price | Done |
| Spread = max(0.5% premium, min tick) | Done (SpreadEngine) |
| Bid = mid - spread/2 | Done |
| Ask = mid + spread/2 | Done |
| Slippage for large size | Done (0.1% per 100 units) |
| Market fills at bid/ask | Done (SpreadEngine.fillPrice) |
| Limit fills on cross | Done (_checkLimitOrderFills) |

### Section 10: Portfolio Engine -- 95%

| Requirement | Status |
|------------|--------|
| Initial balance $100,000 | Done |
| Available margin tracking | Done (marginStatusProvider) |
| Used margin tracking | Done (maintenanceMargin) |
| Unrealized PnL | Done (equity - balance) |
| Realized PnL | Done (TradeRecord, realizedPnLProvider) |
| Trade history | Done (TradeHistoryNotifier, Hive persistence) |
| Recalc on spot update | Done (watches pricesProvider) |
| Recalc on time update | Done (watches tValueProvider) |
| Recalc on vol change | Done (watches rollingVolatilityProvider) |

Remaining: Balance not deducted for limit orders until fill.

### Section 11: Risk Engine -- 95%

| Requirement | Status |
|------------|--------|
| Long margin = premium paid | Done |
| Short margin = stress test (+/-5%) | Done (MarginEngine) |
| Maintenance margin < equity: liquidation | Done |
| Force close at worst bid/ask | Done (closeAllPositions with exit prices) |
| Liquidation notification | Done (SnackBar + banner) |
| Stress test UI | Done (slider -10% to +10% in Risk Dashboard) |

Remaining: Liquidation uses `addPostFrameCallback` in UI -- could be
moved to a proper listener for cleaner architecture.

### Section 12: Screens -- 100%

| Screen | Status | Key Features |
|--------|--------|-------------|
| 1. Asset Selection | Done | BTC/ETH/SOL icons, live spot, expiry countdown |
| 2. Trading Screen | Done | Spot, countdown, options chain with bid/ask, tap to trade |
| 3. Trade Bottom Sheet | Done | Qty, market/limit, bid/ask/spread/IV display, margin preview |
| 4. Portfolio Screen | Done | Balance, margin, positions, close button, **history tab** |
| 5. Risk Dashboard | Done | Net Greeks, stress test slider, margin utilization bar |
| 6. Strategy Builder | Done | Add legs, payoff chart (CustomPaint), Greeks summary |
| 7. Settings | Done | Reset account, volatility mode toggle |
| Navigation | Done | Bottom nav bar (5 tabs) |

Missing from spec: **24h % change** on asset selection (requires tracking
open price or querying 24h ticker data).

### Section 13: Local Storage -- 95%

| Requirement | Status |
|------------|--------|
| Positions persistence | Done (Hive boxPositions) |
| Trade history persistence | Done (Hive boxHistory) |
| Account balance persistence | Done (Hive boxAccount) |
| Settings persistence | Done (Hive boxSettings -- vol mode, expiry) |
| Survives app restart | Done |
| Daily expiry auto-reset on launch | Done (StorageService.init checks last_expiry) |

### Section 14: Performance -- 60%

| Requirement | Status |
|------------|--------|
| No full rebuild every tick | **Partial** -- debounced at 250ms but chain still regenerates |
| Throttle recalculations | Done (250ms debounce on price stream) |
| Isolates for heavy math | **Not done** |
| Avoid jank | Likely OK for small chains (9 strikes) |
| 60fps on mid-range Android | **Not profiled** |

### Section 15: UI Requirements -- 100%

| Requirement | Status |
|------------|--------|
| Dark theme | Done (Binance-style Color(0xFF0B0E11)) |
| Professional trading style | Done |
| Compact typography | Done |
| Color-coded PnL (green/red) | Done |
| Responsive layout | Done |

### Section 16: Edge Cases -- 80%

| Edge Case | Status |
|-----------|--------|
| App opened after expiry -> auto reset | Done (StorageService.init) |
| Timezone -> always UTC | Done |
| WebSocket disconnect -> auto reconnect | Done |
| Extreme volatility -> widen spreads | **Not done** |
| T -> 0 -> intrinsic only | Done |

### Section 18: Code Quality -- 90%

| Requirement | Status |
|------------|--------|
| Null-safe Dart | Done |
| Strong typing | Done |
| Clean architecture | Done |
| Unit tests: Pricing engine | Done (11 tests) |
| Unit tests: Risk/margin engine | Done (7 tests) |
| Unit tests: Volatility engine | Done (8 tests) |
| Unit tests: Spread engine | Done (8 tests) |
| Unit tests: Time engine | Done (5 tests) |
| Separation of concerns | Done (engines have no UI dependency) |
| No business logic in UI | **Partial** -- liquidation trigger is in risk_dashboard.dart |

---

## File Inventory

### Engines (5 files -- all pure Dart, stateless, tested)
- `engines/pricing_engine.dart` -- Black-Scholes with all Greeks
- `engines/time_engine.dart` -- UTC expiry, T calculation, countdown
- `engines/volatility_engine.dart` -- IV skew, rolling realized vol
- `engines/margin_engine.dart` -- Long/short margin, stress test
- `engines/spread_engine.dart` -- Bid/ask, spread, slippage

### Data Layer (2 files)
- `data/market_data_service.dart` -- WebSocket + REST + heartbeat + debounce
- `data/storage_service.dart` -- Hive init, daily expiry reset

### State Management (3 files)
- `features/market_state.dart` -- Providers for prices, time, options chain, limit fills
- `features/portfolio_state.dart` -- Position, TradeRecord, PortfolioNotifier, BalanceNotifier
- `features/risk_state.dart` -- MarginStatus, exit price calculation

### UI (9 files)
- `ui/asset_selection_screen.dart`
- `ui/trading_screen.dart`
- `ui/trade_bottom_sheet.dart`
- `ui/portfolio_screen.dart`
- `ui/risk_dashboard.dart`
- `ui/strategy_builder.dart`
- `ui/settings_screen.dart`
- `ui/navigation_wrapper.dart`
- `ui/theme.dart`

### Tests (5 files, 42 tests total)
- `test/pricing_engine_test.dart` (11)
- `test/volatility_engine_test.dart` (8)
- `test/margin_engine_test.dart` (7)
- `test/spread_engine_test.dart` (8)
- `test/time_engine_test.dart` (5)

---

## What's Left to Reach 100%

### High Priority

1. **In-session expiry handling (Section 5)**
   When T hits 0 while the app is open, auto-close all positions at
   intrinsic value and reset for the next day. Currently only handles
   this on app relaunch.

2. **Extreme volatility spread widening (Section 16)**
   SpreadEngine should widen spreads when realized vol is unusually high.
   Simple rule: if rolling vol > 2x base, multiply spread by 1.5-2x.

3. **24h % change on asset selection (Section 12)**
   Spec says each asset card should show "24h %". Requires either
   storing the opening price or fetching the 24h ticker from REST.

4. **Move liquidation logic out of UI (Section 18)**
   The auto-liquidation trigger is inside `risk_dashboard.dart` using
   `addPostFrameCallback`. Should be a `ref.listen` in a proper
   provider or in `main.dart` for clean separation.

### Medium Priority

5. **Isolates for heavy math (Section 14)**
   Option chain generation runs 9 strikes x 2 types = 18 BS calculations
   on the main thread. For current chain size this is fine, but spec
   calls for isolate readiness. Could wrap in `compute()`.

6. **Profiling on real device (Section 14)**
   Need to verify 60fps on mid-range Android with DevTools.

7. **Max loss/profit display in Strategy Builder (Section 12)**
   The payoff chart is drawn but the numeric max loss/max profit values
   are not displayed explicitly.

### Low Priority

8. **`core/` and `domain/` directories (Section 3)**
   Spec shows these in the architecture diagram. Not functionally
   needed but would match the spec structure.

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
