enum PartyType { customer, supplier }

class PartyModel {
  final String id;
  final String name;
  final String phone;
  final PartyType type;
  final String address;
  double balance; // Positive: They owe us (Lene Hain), Negative: We owe them (Dene Hain)
  final String shopId;

  PartyModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.address = '',
    this.balance = 0.0,
    this.shopId = 'shop_1',
  });

  bool get willGet => balance > 0;
  bool get willGive => balance < 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type == PartyType.customer ? 'customer' : 'supplier',
      'address': address,
      'balance': balance,
      'shopId': shopId,
    };
  }

  factory PartyModel.fromMap(Map<String, dynamic> map) {
    return PartyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] == 'supplier' ? PartyType.supplier : PartyType.customer,
      address: map['address'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      shopId: map['shopId'] ?? 'shop_1',
    );
  }
}
