import '../models/product_model.dart';
import '../models/party_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/order_model.dart';

class MockData {
  // Empty initial products list for fresh real usage
  static List<ProductModel> initialProducts = [];

  // Empty initial parties (Customers & Suppliers)
  static List<PartyModel> initialParties = [];

  // Empty initial ledger entries
  static List<LedgerEntryModel> initialLedgerEntries = [];

  // Empty initial orders
  static List<OrderModel> initialOrders = [];
}
