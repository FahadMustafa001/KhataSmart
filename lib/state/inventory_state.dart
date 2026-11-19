import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'mock_data.dart';
import 'shop_state.dart';

class InventoryState extends ChangeNotifier {
  static final InventoryState instance = InventoryState._();
  InventoryState._() {
    _products.addAll(MockData.initialProducts);
  }

  final List<ProductModel> _products = [];

  // Multi-shop filtering: Only return products belonging to currently active shop
  List<ProductModel> get products {
    final currentShopId = ShopState.instance.activeShopId;
    return _products.where((p) => p.shopId == currentShopId).toList();
  }

  List<ProductModel> get allProductsForDatabase => List.unmodifiable(_products);

  void loadFromDatabase(List<ProductModel> loaded) {
    _products.clear();
    _products.addAll(loaded);
    notifyListeners();
  }

  int get lowStockCount => products.where((p) => p.isLowStock || p.stockQty == 0).length;
  double get totalValuation => products.fold(0.0, (sum, p) => sum + (p.stockQty * p.salePrice));

  void onShopChanged() {
    notifyListeners();
  }

  void addProduct(ProductModel product) {
    if (product.shopId.isEmpty) {
      product.shopId = ShopState.instance.activeShopId;
    }
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

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  ProductModel? findByBarcode(String barcode) {
    try {
      final currentShopId = ShopState.instance.activeShopId;
      return _products.firstWhere(
        (p) => p.shopId == currentShopId && p.barcode == barcode,
      );
    } catch (_) {
      return null;
    }
  }
}
