import 'package:flutter/material.dart';
import '../models/party_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/order_model.dart';
import 'mock_data.dart';

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

  List<PartyModel> get parties => List.unmodifiable(_parties);
  List<LedgerEntryModel> get entries => List.unmodifiable(_entries);
  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<PartyModel> get customers =>
      _parties.where((p) => p.type == PartyType.customer).toList();

  List<PartyModel> get suppliers =>
      _parties.where((p) => p.type == PartyType.supplier).toList();

  // Total Lene Hain (Positive customer balances)
  double get totalReceivable => customers.fold(
      0.0, (sum, p) => p.balance > 0 ? sum + p.balance : sum);

  // Total Dene Hain (Negative supplier balances)
  double get totalPayable => suppliers.fold(
      0.0, (sum, p) => p.balance < 0 ? sum + p.balance.abs() : sum);

  double get todaySales => _orders.fold(0.0, (sum, o) => sum + o.total);

  void addParty(PartyModel party) {
    _parties.insert(0, party);
    notifyListeners();
  }

  void addTransaction({
    required String partyId,
    required LedgerType type,
    required double amount,
    required String note,
  }) {
    final newEntry = LedgerEntryModel(
      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
      partyId: partyId,
      type: type,
      amount: amount,
      note: note,
      date: DateTime.now(),
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
      );
    }
    notifyListeners();
  }

  List<LedgerEntryModel> getEntriesForParty(String partyId) {
    return _entries.where((e) => e.partyId == partyId).toList();
  }
}
