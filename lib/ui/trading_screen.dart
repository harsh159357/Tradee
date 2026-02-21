import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/market_state.dart';
import 'trade_bottom_sheet.dart';

class TradingScreen extends HookConsumerWidget {
  const TradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(selectedAssetProvider);
    final prices = ref.watch(pricesProvider).value ?? {};
    final spot = prices[symbol] ?? 0.0;
    final te = ref.watch(timeProvider);
    final countdown = te.getCountdown();
    final chain = ref.watch(optionsChainProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(symbol,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text('\$${spot.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 14, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(countdown,
                    style: const TextStyle(
                        fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Exp ${te.expiryIST}',
                    style: const TextStyle(
                        fontFamily: 'Courier', fontSize: 9, color: Colors.white38)),
              ],
            ),
          )
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildChainHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: chain.length ~/ 2,
              itemBuilder: (context, index) {
                final call = chain[index * 2];
                final put = chain[index * 2 + 1];
                return _buildOptionRow(context, call, put, symbol, spot);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF1E2329),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Bid', style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text('CALLS', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Ask', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('STRIKE',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Bid', style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text('PUTS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Ask', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(BuildContext context, OptionContract call,
      OptionContract put, String symbol, double spot) {
    final isATM = (call.strike - spot).abs() / spot < 0.015;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isATM ? const Color(0xFF2A2E35) : Colors.transparent,
        border: const Border(
            bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildPriceCell(context, call, true, symbol, spot),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  call.strike.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isATM
                        ? const Color(0xFFF0B90B)
                        : Colors.white,
                  ),
                ),
                if (isATM)
                  const Text('ATM',
                      style: TextStyle(
                          fontSize: 8, color: Color(0xFFF0B90B))),
              ],
            ),
          ),
          _buildPriceCell(context, put, false, symbol, spot),
        ],
      ),
    );
  }

  Widget _buildPriceCell(BuildContext context, OptionContract contract,
      bool isCall, String symbol, double spot) {
    return Expanded(
      flex: 3,
      child: InkWell(
        onTap: () => showTradeBottomSheet(context, contract, symbol, spot),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              contract.spread.bid.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 12,
                color: isCall
                    ? Colors.greenAccent.withAlpha(180)
                    : Colors.redAccent.withAlpha(180),
              ),
            ),
            Column(
              children: [
                Text(
                  '\$${contract.greeks.premium.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isCall ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Δ${contract.greeks.delta.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 9,
                    color: contract.greeks.delta >= 0
                        ? Colors.greenAccent.withAlpha(150)
                        : Colors.redAccent.withAlpha(150),
                  ),
                ),
              ],
            ),
            Text(
              contract.spread.ask.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 12,
                color: isCall
                    ? Colors.greenAccent.withAlpha(180)
                    : Colors.redAccent.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
