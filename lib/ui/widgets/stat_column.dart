import 'package:flutter/material.dart';

class StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double labelSize;
  final double valueSize;

  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.labelSize = 10,
    this.valueSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: Colors.white54, fontSize: labelSize)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }
}
