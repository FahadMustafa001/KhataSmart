import 'package:flutter/material.dart';

/// Renders a realistic visual barcode stripe pattern (e.g. for receipts & scanner preview).
class BarcodeVisualWidget extends StatelessWidget {
  final double height;
  final double? width;
  final Color barColor;
  final int barsCount;

  const BarcodeVisualWidget({
    super.key,
    this.height = 36,
    this.width,
    this.barColor = Colors.black87,
    this.barsCount = 30,
  });

  @override
  Widget build(BuildContext context) {
    final barcodeRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        barsCount,
        (i) {
          final isThick = i % 4 == 0;
          final isMedium = i % 3 == 0;
          final barWidth = isThick ? 2.8 : (isMedium ? 1.8 : 1.1);
          return Container(
            margin: const EdgeInsets.only(right: 1.6),
            width: barWidth,
            height: height,
            color: barColor,
          );
        },
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.fill,
          child: barcodeRow,
        ),
      );
    }

    return barcodeRow;
  }
}
