class CurrencyFormatter {
  /// Converts 1450 to "PKR 1,450" or negative to "-PKR 1,450"
  static String format(double amount, {String prefix = 'PKR '}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return isNegative ? '-$prefix$formatted' : '$prefix$formatted';
  }

  /// Converts 1450 to "Rs. 1,450"
  static String formatRs(double amount) => format(amount, prefix: 'Rs. ');
}
