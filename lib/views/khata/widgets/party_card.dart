import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/party_model.dart';

class PartyCard extends StatelessWidget {
  final PartyModel party;
  final VoidCallback onTap;

  const PartyCard({
    super.key,
    required this.party,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final willGet = party.balance > 0;
    final willGive = party.balance < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
          foregroundColor: AppColors.primaryNavy,
          child: Text(
            party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          party.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.phone, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              party.phone,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(party.balance.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: willGet
                    ? AppColors.green
                    : (willGive ? AppColors.red : AppColors.textMuted),
              ),
            ),
            Text(
              willGet ? 'Lene Hain' : (willGive ? 'Dene Hain' : 'Settled'),
              style: TextStyle(
                fontSize: 11,
                color: willGet
                    ? AppColors.green
                    : (willGive ? AppColors.red : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
