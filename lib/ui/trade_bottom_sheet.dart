import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/market_state.dart';
import '../features/portfolio_state.dart';
import '../engines/spread_engine.dart';

void showTradeBottomSheet(
    BuildContext context, OptionContract contract, String symbol, double spot) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E2329),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        TradeBottomSheet(contract: contract, symbol: symbol, spot: spot),
  );
}

class TradeBottomSheet extends HookConsumerWidget {
  final OptionContract contract;
  final String symbol;
  final double spot;

  const TradeBottomSheet({
    super.key,
    required this.contract,
    required this.symbol,
    required this.spot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qtyController = useTextEditingController(text: '1.0');
    final priceController = useTextEditingController(
      text: contract.greeks.premium.toStringAsFixed(2),
    );
    final orderType = useState<String>('market');

    final qty = double.tryParse(qtyController.text) ?? 0.0;
    final marginPreview = contract.greeks.premium * qty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${contract.type.name.toUpperCase()} ${contract.strike.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'market', label: Text('Market')),
              ButtonSegment(value: 'limit', label: Text('Limit')),
            ],
            selected: {orderType.value},
            onSelectionChanged: (val) => orderType.value = val.first,
          ),
          const SizedBox(height: 16),
          if (orderType.value == 'limit') ...[
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit Price',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
              suffixText: 'Contracts',
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              'Bid', '\$${contract.spread.bid.toStringAsFixed(2)}'),
          _buildInfoRow(
              'Ask', '\$${contract.spread.ask.toStringAsFixed(2)}'),
          _buildInfoRow(
              'Spread', '\$${contract.spread.spread.toStringAsFixed(2)}'),
          _buildInfoRow(
              'IV', '${(contract.iv * 100).toStringAsFixed(1)}%'),
          _buildInfoRow(
              'Est. Margin', '\$${marginPreview.toStringAsFixed(2)}'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _placeOrder(
                    ref,
                    context,
                    1.0,
                    orderType.value,
                    double.tryParse(priceController.text) ?? 0,
                    double.tryParse(qtyController.text) ?? 1,
                  ),
                  child: const Text('BUY / LONG',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _placeOrder(
                    ref,
                    context,
                    -1.0,
                    orderType.value,
                    double.tryParse(priceController.text) ?? 0,
                    double.tryParse(qtyController.text) ?? 1,
                  ),
                  child: const Text('SELL / SHORT',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _placeOrder(WidgetRef ref, BuildContext context, double qtyFactor,
      String oType, double limitPrice, double qty) {
    double entryPrice;
    if (oType == 'market') {
      final rollingVols = ref.read(rollingVolatilityProvider);
      final currentVol = rollingVols[symbol] ?? 0.50;
      entryPrice = SpreadEngine.fillPrice(
        midPrice: contract.greeks.premium,
        quantity: qty * qtyFactor,
        realizedVol: currentVol,
      );
    } else {
      entryPrice = limitPrice;
    }

    final pos = Position(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      strike: contract.strike,
      type: contract.type.name,
      quantity: qty * qtyFactor,
      entryPrice: entryPrice,
      orderType: oType,
      isFilled: oType == 'market',
      timestamp: DateTime.now(),
    );

    ref.read(portfolioProvider.notifier).addOrder(pos);

    if (oType == 'market') {
      final cost = entryPrice * qty * qtyFactor;
      final currentBalance = ref.read(balanceProvider);
      ref.read(balanceProvider.notifier).updateBalance(currentBalance - cost);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(oType == 'market'
            ? 'Filled @ \$${entryPrice.toStringAsFixed(2)}'
            : 'Limit Order Placed @ \$${limitPrice.toStringAsFixed(2)}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
