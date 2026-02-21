# 📄 MASTER SPECIFICATION

# Project: Tradee

---

# 1️⃣ PROJECT OVERVIEW

Build a **mobile-only Flutter application** that simulates **crypto daily options trading**.

This is a **frontend-only demo trading system**.

There is:

* No backend
* No authentication
* No real money
* No server-side storage

The app must simulate a professional crypto options exchange similar in UX philosophy to:

* Deribit
* Binance

But implemented fully client-side.

---

# 2️⃣ CORE CONSTRAINTS (NON-NEGOTIABLE)

1. Flutter mobile only (iOS + Android)
2. Dart only
3. No backend
4. No Firebase
5. No authentication
6. Use real-time spot price APIs (WebSocket)
7. Only daily expiry
8. Only current day expiry
9. Expiry time = 23:59:59 UTC
10. European options
11. Black-Scholes pricing model
12. Local persistence only (Isar or Hive)

---

# 3️⃣ HIGH-LEVEL ARCHITECTURE

App must follow clean architecture principles:

```
lib/
 ├── core/
 ├── data/
 ├── domain/
 ├── engines/
 ├── features/
 ├── ui/
 └── main.dart
```

---

# 4️⃣ MARKET DATA REQUIREMENTS

### Assets Supported:

* BTCUSDT
* ETHUSDT
* SOLUSDT

### Data Source:

WebSocket feed from public exchange API (e.g., Binance public stream).

### Requirements:

* Auto reconnect
* Heartbeat monitoring
* Fallback REST polling every 10 seconds
* Debounce updates to 200–300ms
* Maintain latest spot price in state

---

# 5️⃣ TIME ENGINE REQUIREMENTS

Must compute:

```
T = (expiry_utc - current_utc) / (365 * 24 * 60 * 60)
```

Expiry = Today 23:59:59 UTC.

Time must:

* Update every second
* Emit stream updates
* Trigger re-pricing of options

If T <= 0:

* Expire all options
* Set option value = intrinsic value
* Auto close positions at intrinsic value

---

# 6️⃣ OPTIONS GENERATION RULES

For each asset:

Generate strikes dynamically around ATM:

If spot = S

Strikes:

* S ±1%
* S ±2%
* S ±3%
* S ±5%

Total approx 9–11 strikes.

For each strike:

* Generate Call
* Generate Put

No other expiries allowed.

---

# 7️⃣ PRICING ENGINE REQUIREMENTS

Model: Black-Scholes (European)

Inputs:

* Spot price
* Strike
* Volatility
* Time to expiry
* Risk free rate (constant, configurable)

Outputs:

* Premium
* Delta
* Gamma
* Vega
* Theta

Edge Case:
If T < small_threshold:
Return intrinsic value only.

Engine must be:

* Stateless
* Pure Dart
* Deterministic
* Unit-testable

---

# 8️⃣ VOLATILITY ENGINE

Volatility is locally calculated.

Base volatility:

* Rolling realized volatility (1h window)
  OR
* Configurable constant if history unavailable

Apply skew:

* OTM puts higher IV
* OTM calls slightly lower IV

Optional:
Volatility increases as T decreases.

---

# 9️⃣ ORDER SIMULATION ENGINE

Supported order types:

* Market
* Limit

No stop orders.

Pricing rules:

Mid price = BS price
Spread = max(0.5% of premium, minimum tick)

Bid = mid - spread/2
Ask = mid + spread/2

Slippage:
Large size increases fill price deviation.

Order execution:

* Market fills instantly at bid/ask
* Limit fills only if price crosses

No real matching engine needed.

---

# 🔟 PORTFOLIO ENGINE

Account:

* Initial demo balance (e.g., $100,000)

Track:

* Available margin
* Used margin
* Unrealized PnL
* Realized PnL

Recalculate on:

* Spot update
* Time update
* Volatility change

---

# 1️⃣1️⃣ RISK ENGINE

Margin rules:

Long Options:
Margin = premium paid

Short Options:
Margin = worst-case loss using stress test:

Stress scenario:

* Spot +5%
* Spot -5%

Calculate maximum loss.

Maintenance margin < equity:
Trigger liquidation:

* Force close at worst bid/ask

---

# 1️⃣2️⃣ SCREENS (FINAL LIST)

## 1. Asset Selection Screen

* BTC / ETH / SOL
* Live spot
* 24h %

## 2. Trading Screen

* Spot price
* Countdown timer
* Options chain
* Tap to trade

## 3. Trade Bottom Sheet

* Quantity
* Order type
* Margin preview
* Confirm

## 4. Portfolio Screen

* Balance
* Margin usage
* Positions list
* Close button

## 5. Risk Dashboard

* Net Delta
* Net Gamma
* Net Vega
* Net Theta
* Stress test slider

## 6. Strategy Builder

* Add legs
* Payoff chart
* Max loss/profit
* Greeks summary

## 7. Settings

* Reset account
* Change volatility mode

Navigation:
Bottom navigation bar.

---

# 1️⃣3️⃣ LOCAL STORAGE REQUIREMENTS

Use Isar or Hive.

Persist:

* Positions
* Trade history
* Account balance
* Settings

Data must survive app restart.

---

# 1️⃣4️⃣ PERFORMANCE REQUIREMENTS

* No full rebuild of option chain every tick
* Throttle recalculations
* Use isolates if heavy math
* Avoid jank
* Must support 60fps on mid-range Android device

---

# 1️⃣5️⃣ UI REQUIREMENTS

* Dark theme
* Professional trading style
* Compact typography
* Color-coded PnL
* Green = profit
* Red = loss
* Responsive layout for small devices

---

# 1️⃣6️⃣ EDGE CASES

* App opened after expiry → auto reset
* Time zone differences → always use UTC
* WebSocket disconnect → auto reconnect
* Extreme volatility → widen spreads
* T approaches zero → intrinsic only

---

# 1️⃣7️⃣ EXPLICITLY OUT OF SCOPE

* No real trading
* No deposits
* No backend
* No multi-user
* No real liquidity
* No push notifications
* No calendar spreads
* No multiple expiries

---

# 1️⃣8️⃣ CODE QUALITY REQUIREMENTS

* Null-safe Dart
* Strong typing
* Clean architecture
* Unit tests for:

  * Pricing engine
  * Risk engine
  * Margin logic
* Separation of concerns
* No business logic inside UI widgets

---

# 1️⃣9️⃣ FUTURE EXTENSIBILITY (DO NOT IMPLEMENT NOW)

Design in a way that future versions can add:

* Multiple expiries
* Backend integration
* AI trading engine
* Leaderboards

---

# 🎯 FINAL OUTPUT EXPECTATION FOR CODING AGENTS

The coding agent must:

1. Generate project structure
2. Implement engines first
3. Then implement state management
4. Then implement UI
5. Then connect layers
6. Then add persistence
7. Provide unit tests

---

