enum PartyType { customer, supplier }

class PartyModel {
  final String id;
  final String name;
  final String phone;
  final PartyType type;
  final String address;
  double balance; // Positive: They owe us (Lene Hain), Negative: We owe them (Dene Hain)

  PartyModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.address = '',
    this.balance = 0.0,
  });

  bool get willGet => balance > 0;
  bool get willGive => balance < 0;
}
