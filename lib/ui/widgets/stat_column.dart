import 'package:flutter/material.dart';
import '../theme.dart';

class StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double labelSize;
  final double valueSize;
  final IconData? icon;

  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.labelSize = 11,
    this.valueSize = 15,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(height: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: labelSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
