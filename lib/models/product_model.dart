class ProductModel {
  final String id;
  final String barcode;
  final String title;
  final double costPrice;
  final double salePrice;
  int stockQty;
  final String category;
  final String unit;
  final String urduName;

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
  });

  String get name => title;
  int get stock => stockQty;
  set stock(int val) => stockQty = val;

  double get marginPercentage {
    if (costPrice == 0) return 0.0;
    return ((salePrice - costPrice) / costPrice) * 100;
  }

  bool get isLowStock => stockQty <= 5;
}
