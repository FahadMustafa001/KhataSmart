enum PartyType { customer, supplier }

class PartyModel {
  final String id;
  final String name;
  final String phone;
  final PartyType type;
  final String address;
  final String city;
  final String area;
  final String cnic;
  final double? creditLimit;
  final String notes;
  double balance; // Positive: They owe us (Receivable), Negative: We owe them (Payable)
  final String shopId;
  final DateTime? createdAt;

  PartyModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.address = '',
    this.city = '',
    this.area = '',
    this.cnic = '',
    this.creditLimit,
    this.notes = '',
    this.balance = 0.0,
    this.shopId = 'shop_1',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get willGet => balance > 0;
  bool get willGive => balance < 0;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'KH';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get displayLocation {
    final components = <String>[];
    if (area.trim().isNotEmpty) components.add(area.trim());
    if (city.trim().isNotEmpty) components.add(city.trim());
    if (components.isEmpty && address.trim().isNotEmpty) {
      components.add(address.trim());
    }
    return components.join(', ');
  }

  PartyModel copyWith({
    String? id,
    String? name,
    String? phone,
    PartyType? type,
    String? address,
    String? city,
    String? area,
    String? cnic,
    double? creditLimit,
    String? notes,
    double? balance,
    String? shopId,
    DateTime? createdAt,
  }) {
    return PartyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      address: address ?? this.address,
      city: city ?? this.city,
      area: area ?? this.area,
      cnic: cnic ?? this.cnic,
      creditLimit: creditLimit ?? this.creditLimit,
      notes: notes ?? this.notes,
      balance: balance ?? this.balance,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type == PartyType.customer ? 'customer' : 'supplier',
      'address': address,
      'city': city,
      'area': area,
      'cnic': cnic,
      'creditLimit': creditLimit,
      'notes': notes,
      'balance': balance,
      'shopId': shopId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory PartyModel.fromMap(Map<String, dynamic> map) {
    return PartyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] == 'supplier' ? PartyType.supplier : PartyType.customer,
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      area: map['area'] ?? '',
      cnic: map['cnic'] ?? '',
      creditLimit: (map['creditLimit'] as num?)?.toDouble(),
      notes: map['notes'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      shopId: map['shopId'] ?? 'shop_1',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartyModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
