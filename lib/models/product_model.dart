class ProductModel {
  final String id;
  final String barcode;
  final String title;
  double costPrice;
  final double salePrice;
  int stockQty;
  final String category;
  final String unit;
  final String urduName;
  String shopId;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.title,
    required this.costPrice,
    required this.salePrice,
    required this.stockQty,
    this.category = 'General',
    this.unit = 'Pack',
    this.urduName = '',
    this.shopId = 'shop_1',
  });

  String get name => title;
  int get stock => stockQty;
  set stock(int val) => stockQty = val;
  int get minStockAlert => 5;

  double get marginPercentage {
    if (costPrice == 0) return 0.0;
    return ((salePrice - costPrice) / costPrice) * 100;
  }

  bool get isLowStock => stockQty <= 5;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'title': title,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'stockQty': stockQty,
      'category': category,
      'unit': unit,
      'urduName': urduName,
      'shopId': shopId,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      barcode: map['barcode'] ?? '',
      title: map['title'] ?? '',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0.0,
      stockQty: (map['stockQty'] as num?)?.toInt() ?? 0,
      category: map['category'] ?? 'General',
      unit: map['unit'] ?? 'Pack',
      urduName: map['urduName'] ?? '',
      shopId: map['shopId'] ?? 'shop_1',
    );
  }
}
