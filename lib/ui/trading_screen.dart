import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/market_state.dart';
import '../engines/pricing_engine.dart';
import 'trade_bottom_sheet.dart';

class TradingScreen extends HookConsumerWidget {
  const TradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(selectedAssetProvider);
    final prices = ref.watch(pricesProvider).value ?? {};
    final spot = prices[symbol] ?? 0.0;
    final countdown = ref.watch(timeProvider).getCountdown();
    final chain = ref.watch(optionsChainProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('\$${spot.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(countdown, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          )
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildChainHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: chain.length ~/ 2, // Grouping calls and puts
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('CALLS', textAlign: TextAlign.center, style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
          Expanded(child: Text('STRIKE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
          Expanded(child: Text('PUTS', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildOptionRow(BuildContext context, OptionContract call, OptionContract put, String symbol, double spot) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _buildPriceCell(context, call, true, symbol, spot),
          Expanded(
            child: Text(
              call.strike.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildPriceCell(context, put, false, symbol, spot),
        ],
      ),
    );
  }

  Widget _buildPriceCell(BuildContext context, OptionContract contract, bool isCall, String symbol, double spot) {
    return Expanded(
      child: InkWell(
        onTap: () => showTradeBottomSheet(context, contract, symbol, spot),
        child: Column(
          children: [
            Text(
              '\$${contract.greeks.premium.toStringAsFixed(2)}',
              style: TextStyle(
                color: isCall ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Δ ${contract.greeks.delta.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
