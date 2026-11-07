import 'package:flutter/material.dart';

class StockBadge extends StatelessWidget {
  final int qty;
  final int lowStockThreshold;
  final String? unit;
  final bool showIcon;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StockBadge({
    super.key,
    required this.qty,
    this.lowStockThreshold = 5,
    this.unit,
    this.showIcon = true,
    this.fontSize = 10,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOut = qty <= 0;
    final bool isLow = qty > 0 && qty <= lowStockThreshold;

    final Color bg;
    final Color textColor;
    final Color borderColor;
    final String label;
    final IconData icon;

    if (isOut) {
      bg = const Color(0xFFFEF2F2);
      textColor = const Color(0xFF991B1B);
      borderColor = const Color(0xFFFEE2E2);
      label = 'Out of Stock (0)';
      icon = Icons.block_rounded;
    } else if (isLow) {
      bg = const Color(0xFFFFEDD5);
      textColor = const Color(0xFFC2410C);
      borderColor = const Color(0xFFFED7AA);
      label = 'Only $qty Left!';
      icon = Icons.warning_amber_rounded;
    } else {
      bg = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF2563EB);
      borderColor = const Color(0xFFDBEAFE);
      final unitLabel = (unit != null && unit!.isNotEmpty) ? ' $unit' : ' units';
      label = 'Stock: $qty$unitLabel';
      icon = Icons.inventory_2_outlined;
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
