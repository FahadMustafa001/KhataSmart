import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';


class CartState extends ChangeNotifier {
  static final CartState instance = CartState._();

  CartState._();

  final List<CartItemModel> _items = [];
  double discount = 0.0;

  List<CartItemModel> get items => List.unmodifiable(_items);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get netPayable => (subtotal - discount).clamp(0.0, double.infinity);
  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  void addItem(ProductModel product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItemModel(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void increment(ProductModel product) {
    final item = _items.firstWhere((i) => i.product.id == product.id);
    item.quantity += 1;
    notifyListeners();
  }

  void decrement(ProductModel product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity -= 1;
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void removeItem(ProductModel product) {
    _items.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
