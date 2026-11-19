import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.salePrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      product: ProductModel.fromMap(map['product'] ?? {}),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
