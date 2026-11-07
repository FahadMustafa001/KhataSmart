import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/order_model.dart';

class PaymentModeSelector extends StatelessWidget {
  final PaymentMode selectedMode;
  final ValueChanged<PaymentMode> onModeChanged;

  const PaymentModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.paymentMode,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildOption(
              mode: PaymentMode.cash,
              title: AppStrings.cash,
              icon: Icons.payments,
              color: AppColors.green,
            ),
            const SizedBox(width: 8),
            _buildOption(
              mode: PaymentMode.udhaar,
              title: AppStrings.udhaar,
              icon: Icons.receipt_long,
              color: AppColors.red,
            ),
            const SizedBox(width: 8),
            _buildOption(
              mode: PaymentMode.online,
              title: AppStrings.online,
              icon: Icons.account_balance,
              color: Colors.blue.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption({
    required PaymentMode mode,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
