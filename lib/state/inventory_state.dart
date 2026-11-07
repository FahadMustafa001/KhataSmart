import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'mock_data.dart';

class InventoryState extends ChangeNotifier {
  static final InventoryState instance = InventoryState._();
  InventoryState._() {
    _products.addAll(MockData.initialProducts);
  }

  final List<ProductModel> _products = [];

  List<ProductModel> get products => List.unmodifiable(_products);

  int get lowStockCount => _products.where((p) => p.isLowStock || p.stockQty == 0).length;
  double get totalValuation => _products.fold(0.0, (sum, p) => sum + (p.stockQty * p.salePrice));

  void addProduct(ProductModel product) {
    _products.insert(0, product);
    notifyListeners();
  }

  void addStock(String productId, int qty) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx].stockQty += qty;
      notifyListeners();
    }
  }

  void updateProduct(ProductModel product) {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
    }
  }

  void deductStock(String productId, int qty) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx].stockQty = (_products[idx].stockQty - qty).clamp(0, 999999);
      notifyListeners();
    }
  }

  ProductModel? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }
}
