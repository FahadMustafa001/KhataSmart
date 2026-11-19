import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/purchase_invoice_model.dart';
import '../models/ledger_entry_model.dart';
import 'mock_data.dart';
import 'shop_state.dart';
import 'khata_state.dart';

class InventoryState extends ChangeNotifier {
  static final InventoryState instance = InventoryState._();
  InventoryState._() {
    _products.addAll(MockData.initialProducts);
  }

  final List<ProductModel> _products = [];
  final List<PurchaseInvoiceModel> _purchases = [];

  // Multi-shop filtering: Only return products belonging to currently active shop
  List<ProductModel> get products {
    final currentShopId = ShopState.instance.activeShopId;
    return _products.where((p) => p.shopId == currentShopId).toList();
  }

  List<PurchaseInvoiceModel> get purchases {
    final currentShopId = ShopState.instance.activeShopId;
    return _purchases.where((p) => p.shopId == currentShopId).toList();
  }

  List<ProductModel> get allProductsForDatabase => List.unmodifiable(_products);
  List<PurchaseInvoiceModel> get allPurchasesForDatabase => List.unmodifiable(_purchases);

  void loadFromDatabase(List<ProductModel> loaded, [List<PurchaseInvoiceModel>? loadedPurchases]) {
    _products.clear();
    _products.addAll(loaded);
    if (loadedPurchases != null) {
      _purchases.clear();
      _purchases.addAll(loadedPurchases);
    }
    notifyListeners();
  }

  // Record Stock Inward / Purchase Invoice
  void processPurchaseInvoice(PurchaseInvoiceModel invoice, {bool updateCostPrice = true}) {
    invoice = PurchaseInvoiceModel(
      id: invoice.id.isEmpty ? 'purch_${DateTime.now().millisecondsSinceEpoch}' : invoice.id,
      invoiceNo: invoice.invoiceNo,
      supplierId: invoice.supplierId,
      supplierName: invoice.supplierName,
      date: invoice.date,
      items: invoice.items,
      totalAmount: invoice.totalAmount,
      paidAmount: invoice.paidAmount,
      creditBalanceAdded: invoice.creditBalanceAdded,
      note: invoice.note,
      shopId: ShopState.instance.activeShopId,
    );

    // 1. Increment product stocks
    for (final item in invoice.items) {
      final idx = _products.indexWhere((p) => p.id == item.productId);
      if (idx != -1) {
        _products[idx].stockQty += item.quantity.toInt();
        if (updateCostPrice && item.costPrice > 0) {
          _products[idx].costPrice = item.costPrice;
        }
      }
    }

    // 2. Add ledger entry to supplier's khata if there is a remaining credit balance
    if (invoice.creditBalanceAdded > 0 && invoice.supplierId.isNotEmpty) {
      KhataState.instance.addTransaction(
        partyId: invoice.supplierId,
        type: LedgerType.got, // We owe supplier (Payable / Inflow of inventory)
        amount: invoice.creditBalanceAdded,
        note: 'Stock Inward Bill #${invoice.invoiceNo} (Total: ${invoice.totalAmount.toStringAsFixed(0)}, Paid: ${invoice.paidAmount.toStringAsFixed(0)})',
      );
    }

    // 3. Store invoice
    _purchases.insert(0, invoice);
    notifyListeners();
  }

  int get lowStockCount => products.where((p) => p.isLowStock || p.stockQty == 0).length;
  double get totalValuation => products.fold(0.0, (sum, p) => sum + (p.stockQty * p.salePrice));

  void onShopChanged() {
    notifyListeners();
  }

  void addProduct(ProductModel product) {
    product.shopId = ShopState.instance.activeShopId;
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
