import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/order_model.dart';
import '../models/party_model.dart';
import '../models/product_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/shop_model.dart';
import '../state/inventory_state.dart';
import '../state/khata_state.dart';
import '../state/shop_state.dart';
import 'security_service.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._();
  LocalDatabaseService._();

  static const String _dbFileName = 'khatasmart_local_database.json';
  File? _databaseFile;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Locate the persistent local file
  Future<File> _getFile() async {
    if (_databaseFile != null) return _databaseFile!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _databaseFile = File('${dir.path}/$_dbFileName');
    } catch (_) {
      // Fallback for tests or unsupported environments
      _databaseFile = File('./$_dbFileName');
    }
    return _databaseFile!;
  }

  // 1. Initialize & Load Saved Data on App Startup
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          _loadIntoState(data);
          debugPrint('LocalDatabaseService: Loaded existing offline database successfully.');
        }
      }
    } catch (e) {
      debugPrint('LocalDatabaseService init error: $e');
    }

    _isInitialized = true;

    // Attach reactive listeners so all future mutations auto-persist to disk
    ShopState.instance.addListener(persistToDisk);
    InventoryState.instance.addListener(persistToDisk);
    KhataState.instance.addListener(persistToDisk);
    SecurityService.instance.addListener(persistToDisk);
  }

  // 2. Populate App Singletons with Loaded Data
  void _loadIntoState(Map<String, dynamic> data) {
    // 1. Shops & Active Shop
    if (data['shops'] is List) {
      final loadedShops = (data['shops'] as List)
          .map((m) => ShopModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      if (loadedShops.isNotEmpty) {
        ShopState.instance.loadFromDatabase(
          shops: loadedShops,
          activeShopId: data['activeShopId'] ?? loadedShops.first.id,
        );
      }
    }

    // 2. Products
    if (data['products'] is List) {
      final loadedProducts = (data['products'] as List)
          .map((m) => ProductModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      InventoryState.instance.loadFromDatabase(loadedProducts);
    }

    // 3. Khata Parties, Entries, and Orders
    if (data['parties'] is List || data['entries'] is List || data['orders'] is List) {
      final loadedParties = (data['parties'] as List? ?? [])
          .map((m) => PartyModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      final loadedEntries = (data['entries'] as List? ?? [])
          .map((m) => LedgerEntryModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      final loadedOrders = (data['orders'] as List? ?? [])
          .map((m) => OrderModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();

      KhataState.instance.loadFromDatabase(
        parties: loadedParties,
        entries: loadedEntries,
        orders: loadedOrders,
      );
    }

    // 4. Security Settings
    if (data['security'] is Map) {
      final sec = Map<String, dynamic>.from(data['security']);
      SecurityService.instance.loadFromDatabase(
        isLockEnabled: sec['isLockEnabled'] ?? false,
        isBiometricEnabled: sec['isBiometricEnabled'] ?? false,
        pin: sec['pin'] ?? '',
        question: sec['securityQuestion'],
        answer: sec['securityAnswer'],
      );
    }
  }

  // 3. Atomic Disk Persistence
  bool _isSaving = false;
  Future<void> persistToDisk() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final file = await _getFile();
      final Map<String, dynamic> payload = {
        'version': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
        'activeShopId': ShopState.instance.activeShopId,
        'shops': ShopState.instance.shops.map((s) => s.toMap()).toList(),
        'products': InventoryState.instance.allProductsForDatabase.map((p) => p.toMap()).toList(),
        'parties': KhataState.instance.allPartiesForDatabase.map((p) => p.toMap()).toList(),
        'entries': KhataState.instance.allEntriesForDatabase.map((e) => e.toMap()).toList(),
        'orders': KhataState.instance.allOrdersForDatabase.map((o) => o.toMap()).toList(),
        'security': {
          'isLockEnabled': SecurityService.instance.isLockEnabled,
          'isBiometricEnabled': SecurityService.instance.isBiometricEnabled,
          'pin': SecurityService.instance.hasPinSet ? SecurityService.instance.rawPin : '',
          'securityQuestion': SecurityService.instance.securityQuestion,
          'securityAnswer': SecurityService.instance.rawAnswer,
        },
      };

      final jsonStr = jsonEncode(payload);

      // Safe atomic write (Write to .tmp then rename)
      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsString(jsonStr, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tmpFile.rename(file.path);
    } catch (e) {
      debugPrint('LocalDatabaseService persistToDisk error: $e');
    } finally {
      _isSaving = false;
    }
  }

  // 4. Backup & Restore Helpers for Google Drive & File Export
  Future<String> exportDatabaseJson() async {
    final file = await _getFile();
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '{}';
  }

  Future<bool> restoreDatabaseFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);
      _loadIntoState(data);
      await persistToDisk();
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
