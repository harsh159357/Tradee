# Tradee

A client-side crypto options trading simulator built with Flutter. Practice options trading with real-time market data, Black-Scholes pricing, and professional-grade risk analytics — no backend, no real money, no sign-up.

**[Try it live](https://harsh159357.github.io/Tradee/)**

## What It Does

Tradee simulates a professional crypto options exchange (think Deribit / Binance Options) entirely on the client side. It connects to live Binance WebSocket feeds for real-time spot prices and generates a full options chain with realistic pricing, spreads, and risk metrics.

- **Real-time spot prices** via Binance WebSocket (BTC, ETH, SOL)
- **Black-Scholes pricing** with Greeks (Delta, Gamma, Vega, Theta)
- **Dynamic IV** with skew modeling and rolling realized volatility
- **Market & limit orders** with bid-ask spreads and slippage simulation
- **Portfolio tracking** with live mark-to-market P&L
- **Risk dashboard** with net Greeks and stress-test scenarios
- **Strategy builder** with payoff diagrams and max profit/loss
- **Daily expiry cycle** — positions auto-settle at 23:59:59 UTC

## Screens

| Markets | Trading | Portfolio | Risk | Strategy | Settings |
|---------|---------|-----------|------|----------|----------|
| Asset selector with live spot prices and 24h change | Options chain with calls/puts, tap to trade | Open positions, balance, margin usage, close trades | Net Greeks, stressed P&L, margin status | Multi-leg builder with payoff chart | Reset account, volatility mode toggle |

## Architecture

```
lib/
├── core/          Constants, routing
├── domain/        Pure Dart models (Position, OptionContract, MarginStatus)
├── engines/       Stateless computation (Black-Scholes, volatility, margin, spreads, time)
├── data/          WebSocket + REST market data, Hive storage
├── features/      Riverpod state management
├── ui/            Screens and widgets (zero business logic)
└── main.dart      App entry, liquidation & expiry listeners
```

**Key design choices:**
- Clean architecture — engines are pure Dart, stateless, and unit-tested
- No business logic in UI widgets
- Riverpod for state management with hooks
- `compute()` for chain generation (isolate on native, main-thread on web)
- Hive for local persistence (survives app restart)
- WebSocket with auto-reconnect, heartbeat monitoring, and REST fallback

## How It Works

**Pricing:** Each option is priced using Black-Scholes with inputs from the volatility engine (rolling 1h realized vol with OTM skew). Strikes are generated dynamically around the current spot price.

**Orders:** Market orders fill instantly at bid/ask. Limit orders fill when the mark price crosses the limit. Spreads widen with volatility. Slippage scales with order size.

**Risk:** Long options require premium as margin. Short options use stress-tested margin (spot +/-5%). If equity drops below maintenance margin, all positions are force-liquidated at worst bid/ask.

**Expiry:** All options are European, same-day expiry at 23:59:59 UTC. At expiry, positions settle at intrinsic value. The account resets to $100,000 daily.

## Run Locally

```bash
# Mobile
flutter run

# Web
flutter run -d chrome

# Build for web
flutter build web --release --base-href="/Tradee/"
```

Requires Flutter SDK (stable channel).

## Tech Stack

- **Flutter** — cross-platform UI (iOS, Android, Web)
- **Riverpod + Hooks** — reactive state management
- **go_router** — declarative routing
- **Hive** — lightweight local storage
- **web_socket_channel** — Binance WebSocket feed
- **Black-Scholes** — options pricing model (custom implementation)

## License

This project is for educational and demonstration purposes only. Not financial advice. No real trading occurs.
