import 'package:flutter/material.dart';
import '../models/shop_model.dart';
import 'inventory_state.dart';
import 'khata_state.dart';

class ShopState extends ChangeNotifier {
  static final ShopState instance = ShopState._();
  ShopState._() {
    _shops.add(
      ShopModel(
        id: 'shop_1',
        name: 'My Store',
        ownerName: 'Store Owner',
        phone: '',
        address: '',
        receiptFooter: 'Thank you for shopping with us!',
        paperSize: '58mm',
      ),
    );
    _activeShopId = 'shop_1';
  }

  final List<ShopModel> _shops = [];
  String _activeShopId = 'shop_1';

  List<ShopModel> get shops => List.unmodifiable(_shops);
  String get activeShopId => _activeShopId;

  void loadFromDatabase({
    required List<ShopModel> shops,
    required String activeShopId,
  }) {
    _shops.clear();
    if (shops.isEmpty) {
      _shops.add(
        ShopModel(
          id: 'shop_1',
          name: 'My Store',
          ownerName: 'Store Owner',
          phone: '',
          address: '',
          receiptFooter: 'Thank you for shopping with us!',
          paperSize: '58mm',
        ),
      );
    } else {
      _shops.addAll(shops);
    }

    if (_shops.any((s) => s.id == activeShopId)) {
      _activeShopId = activeShopId;
    } else {
      _activeShopId = _shops.first.id;
    }
    notifyListeners();
    InventoryState.instance.onShopChanged();
    KhataState.instance.onShopChanged();
  }

  ShopModel get activeShop {
    return _shops.firstWhere(
      (s) => s.id == _activeShopId,
      orElse: () => _shops.first,
    );
  }

  void switchShop(String shopId) {
    if (_activeShopId != shopId && _shops.any((s) => s.id == shopId)) {
      _activeShopId = shopId;
      notifyListeners();
      // Inform Inventory & Khata to re-render for this active shop
      InventoryState.instance.onShopChanged();
      KhataState.instance.onShopChanged();
    }
  }

  void addShop({
    required String name,
    required String ownerName,
    required String phone,
    required String address,
    String receiptFooter = 'Thank you for shopping with us!',
    String paperSize = '58mm',
  }) {
    final newId = 'shop_${DateTime.now().millisecondsSinceEpoch}';
    final newShop = ShopModel(
      id: newId,
      name: name.trim().isEmpty ? 'New Branch Store' : name.trim(),
      ownerName: ownerName.trim().isEmpty ? 'Store Owner' : ownerName.trim(),
      phone: phone.trim(),
      address: address.trim(),
      receiptFooter: receiptFooter,
      paperSize: paperSize,
    );
    _shops.add(newShop);
    // Switch to newly created shop
    _activeShopId = newId;
    notifyListeners();
    InventoryState.instance.onShopChanged();
    KhataState.instance.onShopChanged();
  }

  void updateActiveShop({
    String? name,
    String? ownerName,
    String? phone,
    String? address,
    String? receiptFooter,
    String? paperSize,
  }) {
    final current = activeShop;
    if (name != null && name.trim().isNotEmpty) current.name = name.trim();
    if (ownerName != null) current.ownerName = ownerName.trim();
    if (phone != null) current.phone = phone.trim();
    if (address != null) current.address = address.trim();
    if (receiptFooter != null) current.receiptFooter = receiptFooter.trim();
    if (paperSize != null) current.paperSize = paperSize;
    notifyListeners();
  }
}
