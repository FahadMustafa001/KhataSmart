import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/order_model.dart';

class RecentSalesTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const RecentSalesTile({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUdhaar = order.paymentMode == PaymentMode.udhaar;
    final isCash = order.paymentMode == PaymentMode.cash;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : (isUdhaar
                            ? const Color(0xFFFFE4E6)
                            : (isCash
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFDBEAFE))),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isUdhaar
                        ? Icons.person_outline
                        : (isCash ? Icons.point_of_sale : Icons.credit_card),
                    color: isUdhaar
                        ? const Color(0xFFE11D48)
                        : (isCash
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF1D4ED8)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${order.invoiceNo}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isUdhaar
                                      ? const Color(0xFF3F1219)
                                      : (isCash
                                          ? const Color(0xFF0B2B1B)
                                          : const Color(0xFF13233F)))
                                  : (isUdhaar
                                      ? const Color(0xFFFFE4E6)
                                      : (isCash
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFDBEAFE))),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isUdhaar
                                  ? 'Credit'
                                  : (isCash ? 'Cash' : 'Digital'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? (isUdhaar
                                        ? const Color(0xFFFCA5A5)
                                        : (isCash
                                            ? const Color(0xFF86EFAC)
                                            : const Color(0xFF93C5FD)))
                                    : (isUdhaar
                                        ? const Color(0xFFBE123C)
                                        : (isCash
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF1D4ED8))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.customer?.name ?? 'Walk-in Counter'} • ${DateFormatter.formatShort(order.date)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(order.total),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isUdhaar ? 'DUE' : 'PAID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isUdhaar
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
