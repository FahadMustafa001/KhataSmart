import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/ledger_entry_model.dart';

class LedgerEntryRow extends StatelessWidget {
  final LedgerEntryModel entry;

  const LedgerEntryRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isGave = entry.type == LedgerType.gave; // Maine Diye (Udhaar / Outflow)

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Date Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatter.formatShort(entry.date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                '${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Note / Detail
          Expanded(
            child: Text(
              entry.note.isNotEmpty ? entry.note : (isGave ? 'Maine Diye' : 'Maine Wasool Kiye'),
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),

          // Two-column balance entry: Diye (Red) vs Liye (Green)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGave ? AppColors.red.withValues(alpha: 0.08) : AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(entry.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isGave ? AppColors.red : AppColors.green,
                  ),
                ),
                Text(
                  isGave ? 'Maine Diye' : 'Maine Liye',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isGave ? AppColors.red : AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
