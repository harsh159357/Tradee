import 'package:flutter/material.dart';
import '../theme.dart';

class PnLBadge extends StatelessWidget {
  final double value;
  final bool showSign;
  final double fontSize;

  const PnLBadge({
    super.key,
    required this.value,
    this.showSign = true,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = value >= 0;
    final color = isProfit ? AppColors.profit : AppColors.loss;
    final bgColor = isProfit ? AppColors.profitDim : AppColors.lossDim;
    final sign = showSign ? (isProfit ? '+' : '') : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$sign\$${value.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
