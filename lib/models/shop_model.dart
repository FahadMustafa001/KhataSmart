class ShopModel {
  final String id;
  String name;
  String ownerName;
  String phone;
  String address;
  String receiptFooter;
  String paperSize; // '58mm' or '80mm'
  DateTime createdAt;

  ShopModel({
    required this.id,
    required this.name,
    this.ownerName = 'Store Owner',
    this.phone = '',
    this.address = '',
    this.receiptFooter = 'Thank you for shopping with us!',
    this.paperSize = '58mm',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'receiptFooter': receiptFooter,
      'paperSize': paperSize,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      id: map['id'] ?? 'shop_1',
      name: map['name'] ?? 'My Shop',
      ownerName: map['ownerName'] ?? 'Store Owner',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      receiptFooter: map['receiptFooter'] ?? 'Thank you for shopping with us!',
      paperSize: map['paperSize'] ?? '58mm',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
