import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ledger_entry_model.dart';
import '../../../state/khata_state.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

class AddTransactionModal extends StatefulWidget {
  final String partyId;
  final String partyName;
  final LedgerType initialType;

  const AddTransactionModal({
    super.key,
    required this.partyId,
    required this.partyName,
    required this.initialType,
  });

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late LedgerType _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    KhataState.instance.addTransaction(
      partyId: widget.partyId,
      type: _type,
      amount: amount,
      note: _noteController.text.trim().isEmpty
          ? (_type == LedgerType.gave ? 'Maine Diye' : 'Maine Wasool Kiye')
          : _noteController.text.trim(),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isGave = _type == LedgerType.gave;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction: ${widget.partyName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Segmented Switch: Maine Diye (Red) vs Maine Wasool Kiye (Green)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = LedgerType.gave),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isGave ? AppColors.red : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Maine Diye (-)',
                      style: TextStyle(
                        color: isGave ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = LedgerType.got),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isGave ? AppColors.green : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Maine Wasool Kiye (+)',
                      style: TextStyle(
                        color: !isGave ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Amount Field
          CustomTextField(
            label: 'Amount (Rs.)',
            hint: '0',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_exchange,
            controller: _amountController,
          ),

          const SizedBox(height: 12),

          // Note / Detail
          CustomTextField(
            label: 'Detail / Description (Tafseel)',
            hint: 'e.g. Samaan udhaar diya, or Cash payment',
            controller: _noteController,
          ),

          const SizedBox(height: 20),

          // Save button
          CustomButton(
            text: isGave ? 'Save (Maine Diye)' : 'Save (Maine Wasool Kiye)',
            icon: Icons.check,
            color: isGave ? AppColors.red : AppColors.green,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
