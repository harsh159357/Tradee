import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../features/market_state.dart';
import 'theme.dart';
import 'trade_bottom_sheet.dart';

class TradingScreen extends HookConsumerWidget {
  const TradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(selectedAssetProvider);
    final pricesAsync = ref.watch(pricesProvider);
    final prices = pricesAsync.value ?? {};
    final spot = prices[symbol] ?? 0.0;
    final te = ref.watch(timeProvider);
    final countdown = te.getCountdown();
    final chainAsync = ref.watch(optionsChainProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, symbol, spot, countdown, te.expiryIST, pricesAsync),
            _buildChainHeader(context),
            Expanded(child: _buildChainBody(context, ref, chainAsync, symbol, spot)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String symbol, double spot,
      String countdown, String expiryIST, AsyncValue pricesAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          spot > 0 ? '\$${spot.toStringAsFixed(2)}' : 'Loading...',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.profit,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (pricesAsync is AsyncLoading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      countdown,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Exp $expiryIST',
                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChainBody(BuildContext context, WidgetRef ref,
      AsyncValue<List<OptionContract>> chainAsync, String symbol, double spot) {
    final chain = chainAsync.value ?? [];

    if (chain.isEmpty && chainAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (chain.isEmpty && chainAsync.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.lossDim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.error_outline, size: 32, color: AppColors.loss),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load chain: ${chainAsync.error}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(optionsChainProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: chain.length ~/ 2,
      itemBuilder: (context, index) {
        final call = chain[index * 2];
        final put = chain[index * 2 + 1];
        return _OptionRow(
          call: call,
          put: put,
          symbol: symbol,
          spot: spot,
          isEven: index.isEven,
        );
      },
    );
  }

  Widget _buildChainHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Bid', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
                Text('CALLS', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                Text('Ask', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('STRIKE',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Bid', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
                Text('PUTS', style: TextStyle(color: AppColors.loss, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                Text('Ask', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final OptionContract call;
  final OptionContract put;
  final String symbol;
  final double spot;
  final bool isEven;

  const _OptionRow({
    required this.call,
    required this.put,
    required this.symbol,
    required this.spot,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    final isATM = (call.strike - spot).abs() / spot < AppConstants.atmThreshold;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isATM
            ? AppColors.primaryDim
            : isEven
                ? Colors.transparent
                : AppColors.surface.withAlpha(80),
        border: isATM
            ? const Border.symmetric(
                horizontal: BorderSide(color: AppColors.primary, width: 0.5))
            : const Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.3)),
      ),
      child: Row(
        children: [
          _PriceCell(contract: call, isCall: true, symbol: symbol, spot: spot),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  call.strike.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isATM ? AppColors.primary : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (isATM)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ATM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _PriceCell(contract: put, isCall: false, symbol: symbol, spot: spot),
        ],
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final OptionContract contract;
  final bool isCall;
  final String symbol;
  final double spot;

  const _PriceCell({
    required this.contract,
    required this.isCall,
    required this.symbol,
    required this.spot,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isCall ? AppColors.profit : AppColors.loss;

    return Expanded(
      flex: 3,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showTradeBottomSheet(context, contract, symbol, spot),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  contract.spread.bid.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 12,
                    color: accent.withAlpha(160),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '\$${contract.greeks.premium.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Δ ${contract.greeks.delta.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Text(
                  contract.spread.ask.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 12,
                    color: accent.withAlpha(160),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
