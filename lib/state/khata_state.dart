import 'package:flutter/material.dart';
import '../models/party_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/order_model.dart';
import 'mock_data.dart';
import 'shop_state.dart';

class KhataState extends ChangeNotifier {
  static final KhataState instance = KhataState._();
  KhataState._() {
    _parties.addAll(MockData.initialParties);
    _entries.addAll(MockData.initialLedgerEntries);
    _orders.addAll(MockData.initialOrders);
  }

  final List<PartyModel> _parties = [];
  final List<LedgerEntryModel> _entries = [];
  final List<OrderModel> _orders = [];

  // Multi-shop filtering: Only return items belonging to active shop
  List<PartyModel> get parties {
    final currentShopId = ShopState.instance.activeShopId;
    return _parties.where((p) => p.shopId == currentShopId).toList();
  }

  List<LedgerEntryModel> get entries {
    final currentShopId = ShopState.instance.activeShopId;
    return _entries.where((e) => e.shopId == currentShopId).toList();
  }

  List<OrderModel> get orders {
    final currentShopId = ShopState.instance.activeShopId;
    return _orders.where((o) => o.shopId == currentShopId).toList();
  }

  List<PartyModel> get allPartiesForDatabase => List.unmodifiable(_parties);
  List<LedgerEntryModel> get allEntriesForDatabase => List.unmodifiable(_entries);
  List<OrderModel> get allOrdersForDatabase => List.unmodifiable(_orders);

  void loadFromDatabase({
    required List<PartyModel> parties,
    required List<LedgerEntryModel> entries,
    required List<OrderModel> orders,
  }) {
    _parties.clear();
    _parties.addAll(parties);
    _entries.clear();
    _entries.addAll(entries);
    _orders.clear();
    _orders.addAll(orders);
    notifyListeners();
  }

  List<PartyModel> get customers =>
      parties.where((p) => p.type == PartyType.customer).toList();

  List<PartyModel> get suppliers =>
      parties.where((p) => p.type == PartyType.supplier).toList();

  // Total Lene Hain (Positive customer balances)
  double get totalReceivable => customers.fold(
      0.0, (sum, p) => p.balance > 0 ? sum + p.balance : sum);

  // Total Dene Hain (Negative supplier balances)
  double get totalPayable => suppliers.fold(
      0.0, (sum, p) => p.balance < 0 ? sum + p.balance.abs() : sum);

  double get todaySales => orders.fold(0.0, (sum, o) => sum + o.total);

  void onShopChanged() {
    notifyListeners();
  }

  void addParty(PartyModel party) {
    if (party.shopId.isEmpty) {
      // party.shopId default is already 'shop_1' or active
    }
    _parties.insert(0, party);
    notifyListeners();
  }

  void deleteParty(String partyId) {
    _parties.removeWhere((p) => p.id == partyId);
    _entries.removeWhere((e) => e.partyId == partyId);
    notifyListeners();
  }

  void addTransaction({
    required String partyId,
    required LedgerType type,
    required double amount,
    required String note,
    String? shopId,
  }) {
    final currentShopId = shopId ?? ShopState.instance.activeShopId;
    final newEntry = LedgerEntryModel(
      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
      partyId: partyId,
      type: type,
      amount: amount,
      note: note,
      date: DateTime.now(),
      shopId: currentShopId,
    );
    _entries.insert(0, newEntry);

    // Update Party Balance
    final party = _parties.firstWhere((p) => p.id == partyId);
    if (type == LedgerType.gave) {
      party.balance += amount; // We gave goods/loan -> balance increases (owe us more)
    } else {
      party.balance -= amount; // We received cash -> balance decreases
    }
    notifyListeners();
  }

  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    if (order.paymentMode == PaymentMode.udhaar && order.customer != null) {
      addTransaction(
        partyId: order.customer!.id,
        type: LedgerType.gave,
        amount: order.total,
        note: 'Bill #${order.invoiceNo}',
        shopId: order.shopId,
      );
    }
    notifyListeners();
  }

  List<LedgerEntryModel> getEntriesForParty(String partyId) {
    return entries.where((e) => e.partyId == partyId).toList();
  }
}
