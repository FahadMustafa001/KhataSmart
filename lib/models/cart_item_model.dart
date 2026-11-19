import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  final double costPriceAtSale;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    double? costPriceAtSale,
  }) : costPriceAtSale = costPriceAtSale ?? product.costPrice;

  double get subtotal => product.salePrice * quantity;
  String get productName => product.name;
  double get sellingPrice => product.salePrice;
  double get totalPrice => subtotal;

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'costPriceAtSale': costPriceAtSale,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    final prod = ProductModel.fromMap(map['product'] ?? {});
    return CartItemModel(
      product: prod,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      costPriceAtSale: (map['costPriceAtSale'] as num?)?.toDouble() ?? prod.costPrice,
    );
  }
}
