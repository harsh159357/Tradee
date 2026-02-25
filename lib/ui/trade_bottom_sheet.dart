import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../features/market_state.dart';
import '../features/portfolio_state.dart';
import 'theme.dart';
import 'widgets/info_row.dart';

void showTradeBottomSheet(
    BuildContext context, OptionContract contract, String symbol, double spot) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
          left: BorderSide(color: AppColors.surfaceBorder),
          right: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: TradeBottomSheet(contract: contract, symbol: symbol, spot: spot),
    ),
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
    final isCall = contract.type == OptionType.call;
    final accent = isCall ? AppColors.profit : AppColors.loss;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withAlpha(60)),
                ),
                child: Icon(
                  isCall ? Icons.trending_up : Icons.trending_down,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${contract.type.name.toUpperCase()} ${contract.strike.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '$symbol  ·  IV ${(contract.iv * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                _OrderTypeTab(
                  label: 'Market',
                  isSelected: orderType.value == 'market',
                  onTap: () => orderType.value = 'market',
                ),
                _OrderTypeTab(
                  label: 'Limit',
                  isSelected: orderType.value == 'limit',
                  onTap: () => orderType.value = 'limit',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (orderType.value == 'limit') ...[
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit Price',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _StepperButton(
                    icon: Icons.add,
                    onTap: () {
                      final cur = double.tryParse(qtyController.text) ?? 0;
                      qtyController.text = (cur + 1).toStringAsFixed(1);
                    },
                  ),
                  const SizedBox(height: 4),
                  _StepperButton(
                    icon: Icons.remove,
                    onTap: () {
                      final cur = double.tryParse(qtyController.text) ?? 0;
                      if (cur > 1) {
                        qtyController.text = (cur - 1).toStringAsFixed(1);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                InfoRow(label: 'Bid', value: '\$${contract.spread.bid.toStringAsFixed(2)}'),
                InfoRow(label: 'Ask', value: '\$${contract.spread.ask.toStringAsFixed(2)}'),
                InfoRow(label: 'Spread', value: '\$${contract.spread.spread.toStringAsFixed(2)}'),
                InfoRow(
                  label: 'Est. Margin',
                  value: '\$${marginPreview.toStringAsFixed(2)}',
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TradeButton(
                  label: 'BUY / LONG',
                  color: AppColors.profit,
                  onTap: () => _confirmAndPlace(
                    ref, context, 1.0, orderType.value,
                    double.tryParse(priceController.text) ?? 0,
                    double.tryParse(qtyController.text) ?? 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TradeButton(
                  label: 'SELL / SHORT',
                  color: AppColors.loss,
                  onTap: () => _confirmAndPlace(
                    ref, context, -1.0, orderType.value,
                    double.tryParse(priceController.text) ?? 0,
                    double.tryParse(qtyController.text) ?? 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmAndPlace(WidgetRef ref, BuildContext context, double qtyFactor,
      String oType, double limitPrice, double qty) {
    final side = qtyFactor > 0 ? 'BUY' : 'SELL';
    final typeLabel = contract.type.name.toUpperCase();
    final priceLabel = oType == 'market' ? 'Market' : '\$${limitPrice.toStringAsFixed(2)}';
    final accent = qtyFactor > 0 ? AppColors.profit : AppColors.loss;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder),
            left: BorderSide(color: AppColors.surfaceBorder),
            right: BorderSide(color: AppColors.surfaceBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Confirm $side',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  InfoRow(label: 'Side', value: side),
                  InfoRow(label: 'Contract', value: '$typeLabel ${contract.strike.toStringAsFixed(0)}'),
                  InfoRow(label: 'Quantity', value: qty.toStringAsFixed(1)),
                  InfoRow(label: 'Order Type', value: oType.toUpperCase()),
                  InfoRow(label: 'Price', value: priceLabel),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TradeButton(
                    label: 'CONFIRM $side',
                    color: accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _placeOrder(ref, context, qtyFactor, oType, limitPrice, qty);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _placeOrder(WidgetRef ref, BuildContext context, double qtyFactor,
      String oType, double limitPrice, double qty) async {
    final rollingVols = ref.read(rollingVolatilityProvider);
    final currentVol = rollingVols[symbol] ?? AppConstants.defaultBaseVolatility;

    final result = await ref.read(portfolioProvider.notifier).placeOrder(
      symbol: symbol,
      strike: contract.strike,
      type: contract.type.name,
      quantity: qty,
      qtyFactor: qtyFactor,
      orderType: oType,
      midPrice: contract.greeks.premium,
      limitPrice: limitPrice,
      currentVol: currentVol,
      balanceNotifier: ref.read(balanceProvider.notifier),
      currentBalance: ref.read(balanceProvider),
    );

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: AppColors.profit,
      ),
    );
  }
}

class _OrderTypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTypeTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDim : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TradeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TradeButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
