enum LedgerType { gave, got } // gave = Maine Diye, got = Maine Wasool Kiye

class LedgerEntryModel {
  final String id;
  final String partyId;
  final LedgerType type;
  final double amount;
  final String note;
  final DateTime date;

  LedgerEntryModel({
    required this.id,
    required this.partyId,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });
}
