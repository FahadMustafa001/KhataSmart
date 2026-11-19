enum LedgerType { gave, got } // gave = Maine Diye, got = Maine Wasool Kiye

class LedgerEntryModel {
  final String id;
  final String partyId;
  final LedgerType type;
  final double amount;
  final String note;
  final DateTime date;
  final String shopId;

  LedgerEntryModel({
    required this.id,
    required this.partyId,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
    this.shopId = 'shop_1',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyId': partyId,
      'type': type == LedgerType.gave ? 'gave' : 'got',
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'shopId': shopId,
    };
  }

  factory LedgerEntryModel.fromMap(Map<String, dynamic> map) {
    return LedgerEntryModel(
      id: map['id'] ?? '',
      partyId: map['partyId'] ?? '',
      type: map['type'] == 'got' ? LedgerType.got : LedgerType.gave,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      shopId: map['shopId'] ?? 'shop_1',
    );
  }
}
