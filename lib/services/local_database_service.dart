import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/order_model.dart';
import '../models/party_model.dart';
import '../models/product_model.dart';
import '../models/purchase_invoice_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/shop_model.dart';
import '../state/inventory_state.dart';
import '../state/khata_state.dart';
import '../state/shop_state.dart';
import 'cloud_sync_service.dart';
import 'google_drive_service.dart';
import 'notification_service.dart';
import 'security_service.dart';

/// Pure SQLite Relational Database Engine powered by `sqflite`.
/// 100% database operations run directly against `smartkhata_sqlite.db`.
class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._();
  LocalDatabaseService._();

  static const String _sqliteDbName = 'smartkhata_sqlite.db';

  Database? _db;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _loadFailed = false;
  bool _listenersAttached = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;

  /// Direct handle to the underlying SQLite database
  Future<Database?> get database async {
    if (_db != null && _db!.isOpen) return _db;
    await init();
    return _db;
  }

  /// 1. Initialize SQLite Database, Create Relational Tables, and Load State
  Future<void> init({bool forceRetry = false}) async {
    if (_isInitialized && !forceRetry) return;
    if (_isLoading) return;

    _isLoading = true;
    _isInitialized = false;

    bool loadSucceeded = false;

    try {
      if (kIsWeb) {
        debugPrint(
            'LocalDatabaseService: Web environment detected. Initializing web fallback.');
        _isInitialized = true;
        _isLoading = false;
        _attachListeners();
        return;
      }

      final databasesPath = await getDatabasesPath();
      final dbPath = p.join(databasesPath, _sqliteDbName);

      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _onCreateSqliteDatabase,
        onConfigure: (db) async {
          // Enable Foreign Keys for relational integrity
          await db.execute('PRAGMA foreign_keys = ON;');
        },
      );

      debugPrint(
          'LocalDatabaseService: Pure SQLite database opened at: $dbPath');

      // Read directly from SQLite tables into reactive View-Model singletons
      await _loadFromSqliteIntoState();
      loadSucceeded = true;
    } catch (e) {
      _loadFailed = true;
      debugPrint('LocalDatabaseService SQLite init error: $e');
    } finally {
      _isLoading = false;
    }

    _isInitialized = true;

    if (!loadSucceeded || _loadFailed) {
      _loadFailed = true;
      return;
    }

    _loadFailed = false;
    _attachListeners();
  }

  /// Creates production relational tables and B-Tree indexes
  Future<void> _onCreateSqliteDatabase(Database db, int version) async {
    // 1. Shops Configuration Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        owner_name TEXT,
        phone TEXT,
        address TEXT,
        currency_symbol TEXT DEFAULT 'Rs.',
        receipt_footer_note TEXT,
        data_json TEXT NOT NULL
      );
    ''');

    // 2. Master Product Inventory Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        shop_id TEXT,
        barcode TEXT,
        name TEXT NOT NULL,
        purchase_price REAL NOT NULL DEFAULT 0.0,
        sale_price REAL NOT NULL DEFAULT 0.0,
        stock_quantity REAL NOT NULL DEFAULT 0.0,
        min_stock_alert REAL NOT NULL DEFAULT 5.0,
        unit TEXT NOT NULL DEFAULT 'Piece',
        category TEXT DEFAULT 'General',
        data_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);');

    // 3. Supplier Purchases & Inwards Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id TEXT PRIMARY KEY,
        supplier_id TEXT,
        supplier_name TEXT,
        invoice_number TEXT,
        total_amount REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        balance_amount REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        data_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_purchases_created ON purchases(created_at);');

    // 4. Commercial Parties Table (Customers & Suppliers)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parties (
        id TEXT PRIMARY KEY,
        shop_id TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        party_type TEXT NOT NULL,
        current_balance REAL NOT NULL DEFAULT 0.0,
        credit_limit REAL DEFAULT 0.0,
        data_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_parties_phone ON parties(phone);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_parties_type ON parties(party_type);');

    // 5. Financial Ledger Entries Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ledger_entries (
        id TEXT PRIMARY KEY,
        party_id TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0.0,
        entry_type TEXT NOT NULL,
        running_balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        data_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_party ON ledger_entries(party_id);');

    // 6. Retail Sales Orders Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        customer_party_id TEXT,
        total_amount REAL NOT NULL DEFAULT 0.0,
        cash_received REAL NOT NULL DEFAULT 0.0,
        online_received REAL NOT NULL DEFAULT 0.0,
        credit_amount REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        data_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at);');

    // 7. Key-Value Application Metadata & Settings Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value_json TEXT NOT NULL
      );
    ''');

    debugPrint(
        'LocalDatabaseService: All 7 SQLite relational tables and B-Tree indexes created in smartkhata_sqlite.db.');
  }

  /// Reads from SQLite tables directly and hydrates in-memory ViewModels
  Future<void> _loadFromSqliteIntoState() async {
    if (_db == null || !_db!.isOpen) return;

    // 1. Load Shops
    final shopsRows = await _db!.query('shops');
    final List<ShopModel> parsedShops = shopsRows.map((row) {
      final jsonStr = row['data_json'] as String;
      return ShopModel.fromMap(Map<String, dynamic>.from(jsonDecode(jsonStr)));
    }).toList();

    // Load active shop ID and onboarding state from SQLite app_metadata table
    final metadataRows = await _db!.query('app_metadata');
    final Map<String, dynamic> metadata = {};
    for (final row in metadataRows) {
      final k = row['key'] as String;
      final v = row['value_json'] as String;
      try {
        metadata[k] = jsonDecode(v);
      } catch (_) {
        metadata[k] = v;
      }
    }

    final String? activeShopId = metadata['activeShopId'] as String?;
    final bool? hasCompletedOnboarding =
        metadata['hasCompletedOnboarding'] as bool?;

    if (parsedShops.isNotEmpty) {
      ShopState.instance.loadFromDatabase(
        shops: parsedShops,
        activeShopId: activeShopId ?? parsedShops.first.id,
        hasCompletedOnboarding: hasCompletedOnboarding,
      );
    }

    // 2. Load Products & Purchases directly from SQLite
    final productsRows = await _db!.query('products', orderBy: 'name ASC');
    final List<ProductModel> parsedProducts = productsRows.map((row) {
      final jsonStr = row['data_json'] as String;
      return ProductModel.fromMap(
          Map<String, dynamic>.from(jsonDecode(jsonStr)));
    }).toList();

    final purchasesRows =
        await _db!.query('purchases', orderBy: 'created_at DESC');
    final List<PurchaseInvoiceModel> parsedPurchases = purchasesRows.map((row) {
      final jsonStr = row['data_json'] as String;
      return PurchaseInvoiceModel.fromMap(
          Map<String, dynamic>.from(jsonDecode(jsonStr)));
    }).toList();

    InventoryState.instance.loadFromDatabase(parsedProducts, parsedPurchases);

    // 3. Load Parties, Ledger Entries, and Orders directly from SQLite
    final partiesRows = await _db!.query('parties', orderBy: 'name ASC');
    final List<PartyModel> parsedParties = partiesRows.map((row) {
      final jsonStr = row['data_json'] as String;
      return PartyModel.fromMap(Map<String, dynamic>.from(jsonDecode(jsonStr)));
    }).toList();

    final entriesRows =
        await _db!.query('ledger_entries', orderBy: 'created_at ASC');
    final List<LedgerEntryModel> parsedEntries = entriesRows.map((row) {
      final jsonStr = row['data_json'] as String;
      return LedgerEntryModel.fromMap(
          Map<String, dynamic>.from(jsonDecode(jsonStr)));
    }).toList();

    final ordersRows = await _db!.query('orders', orderBy: 'created_at DESC');
    final List<OrderModel> parsedOrders = ordersRows.map((row) {
      final jsonStr = row['data_json'] as String;
      return OrderModel.fromMap(Map<String, dynamic>.from(jsonDecode(jsonStr)));
    }).toList();

    KhataState.instance.loadFromDatabase(
      parties: parsedParties,
      entries: parsedEntries,
      orders: parsedOrders,
    );

    // 4. Load Security Settings from SQLite
    if (metadata['security'] is Map) {
      final parsedSecurity = Map<String, dynamic>.from(metadata['security']);
      SecurityService.instance.loadFromDatabase(
        isLockEnabled: parsedSecurity['isLockEnabled'] ?? false,
        isBiometricEnabled: parsedSecurity['isBiometricEnabled'] ?? false,
        pinHash: parsedSecurity['pinHash'],
        pinSalt: parsedSecurity['pinSalt'],
        pin: parsedSecurity['pin'],
        question: parsedSecurity['securityQuestion'],
        answerHash: parsedSecurity['answerHash'],
        answerSalt: parsedSecurity['answerSalt'],
        answer: parsedSecurity['securityAnswer'],
      );
    }

    // 5. Load Google Drive Metadata from SQLite
    if (metadata['googleDrive'] is Map) {
      GoogleDriveService.instance
          .loadFromDatabase(Map<String, dynamic>.from(metadata['googleDrive']));
    }

    // 6. Load Notifications from SQLite
    if (metadata['notifications'] is List) {
      NotificationService.instance
          .loadFromDatabase(List<dynamic>.from(metadata['notifications']));
    }
    NotificationService.instance.init();

    debugPrint(
        'LocalDatabaseService: SQLite direct load complete (${parsedProducts.length} products, ${parsedParties.length} parties, ${parsedOrders.length} orders).');
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    ShopState.instance.addListener(schedulePersist);
    InventoryState.instance.addListener(schedulePersist);
    KhataState.instance.addListener(schedulePersist);
    SecurityService.instance.addListener(schedulePersist);
    NotificationService.instance.addListener(schedulePersist);
  }

  // 3. Debouncing & Coalescing Persistence
  Timer? _debounceTimer;
  Future<void>? _activeSaveFuture;
  bool _hasPendingSave = false;

  void schedulePersist() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      persistToDisk().catchError((e) {
        debugPrint('Automatic SQLite persistence skipped or failed: $e');
      });
    });
  }

  Future<void> persistToDisk() {
    _debounceTimer?.cancel();

    if (_loadFailed || _isLoading) {
      debugPrint(
          'LocalDatabaseService: Skipping persistToDisk because database is loading or load failed.');
      return Future.error(StateError(
        'Cannot persist to disk while database is loading or load failed. Please restore from backup or clear data to recover.',
      ));
    }

    if (_activeSaveFuture != null) {
      _hasPendingSave = true;
      return _activeSaveFuture!;
    }

    final completer = Completer<void>();
    _activeSaveFuture = completer.future;

    () async {
      try {
        while (true) {
          _hasPendingSave = false;
          await _performWrite();
          if (!_hasPendingSave) {
            break;
          }
        }
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _activeSaveFuture = null;
      }
    }();

    return _activeSaveFuture!;
  }

  /// Writes all active state data directly into SQLite relational tables via an atomic transaction.
  /// Zero local JSON files are created or touched on disk.
  Future<void> _performWrite() async {
    if (kIsWeb) return;
    try {
      final Map<String, dynamic> payload = {
        'version': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
        'activeShopId': ShopState.instance.activeShopId,
        'hasCompletedOnboarding': ShopState.instance.hasCompletedOnboarding,
        'shops': ShopState.instance.shops.map((s) => s.toMap()).toList(),
        'products': InventoryState.instance.allProductsForDatabase
            .map((p) => p.toMap())
            .toList(),
        'purchases': InventoryState.instance.allPurchasesForDatabase
            .map((p) => p.toMap())
            .toList(),
        'parties': KhataState.instance.allPartiesForDatabase
            .map((p) => p.toMap())
            .toList(),
        'entries': KhataState.instance.allEntriesForDatabase
            .map((e) => e.toMap())
            .toList(),
        'orders': KhataState.instance.allOrdersForDatabase
            .map((o) => o.toMap())
            .toList(),
        'security': SecurityService.instance.toDatabaseMap(),
        'googleDrive': GoogleDriveService.instance.toMap(),
        'notifications': NotificationService.instance.toDatabaseList(),
      };

      // Commit to SQLite Relational Tables Atomically
      if (_db != null && _db!.isOpen) {
        await _writeJsonDataIntoSqlite(payload);
      }

      // Trigger debounced background replication to Cloud Firestore
      CloudSyncService.instance.scheduleAutoSync();
    } catch (e) {
      debugPrint('LocalDatabaseService _performWrite SQLite error: $e');
    }
  }

  /// Helper that writes payload into SQLite relational tables using an atomic transaction
  Future<void> _writeJsonDataIntoSqlite(Map<String, dynamic> data) async {
    if (_db == null || !_db!.isOpen) return;

    await _db!.transaction((txn) async {
      final batch = txn.batch();

      // Upsert Shops
      if (data['shops'] is List) {
        batch.delete('shops');
        for (final item in data['shops']) {
          final m = Map<String, dynamic>.from(item);
          batch.insert(
            'shops',
            {
              'id': m['id'] ?? '',
              'name': m['name'] ?? '',
              'owner_name': m['ownerName'],
              'phone': m['phone'],
              'address': m['address'],
              'currency_symbol': m['currencySymbol'] ?? 'Rs.',
              'receipt_footer_note': m['receiptFooterNote'],
              'data_json': jsonEncode(m),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Upsert Products
      if (data['products'] is List) {
        batch.delete('products');
        for (final item in data['products']) {
          final m = Map<String, dynamic>.from(item);
          batch.insert(
            'products',
            {
              'id': m['id'] ?? '',
              'shop_id': m['shopId'],
              'barcode': m['barcode'],
              'name': m['name'] ?? '',
              'purchase_price': (m['purchasePrice'] as num?)?.toDouble() ?? 0.0,
              'sale_price': (m['salePrice'] as num?)?.toDouble() ?? 0.0,
              'stock_quantity': (m['stockQuantity'] as num?)?.toDouble() ?? 0.0,
              'min_stock_alert':
                  (m['minStockAlert'] as num?)?.toDouble() ?? 5.0,
              'unit': m['unit'] ?? 'Piece',
              'category': m['category'] ?? 'General',
              'data_json': jsonEncode(m),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Upsert Purchases
      if (data['purchases'] is List) {
        batch.delete('purchases');
        for (final item in data['purchases']) {
          final m = Map<String, dynamic>.from(item);
          batch.insert(
            'purchases',
            {
              'id': m['id'] ?? '',
              'supplier_id': m['supplierId'],
              'supplier_name': m['supplierName'],
              'invoice_number': m['invoiceNumber'],
              'total_amount': (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
              'paid_amount': (m['paidAmount'] as num?)?.toDouble() ?? 0.0,
              'balance_amount': (m['balanceAmount'] as num?)?.toDouble() ?? 0.0,
              'created_at': m['createdAt'] ?? DateTime.now().toIso8601String(),
              'data_json': jsonEncode(m),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Upsert Parties
      if (data['parties'] is List) {
        batch.delete('parties');
        for (final item in data['parties']) {
          final m = Map<String, dynamic>.from(item);
          batch.insert(
            'parties',
            {
              'id': m['id'] ?? '',
              'shop_id': m['shopId'],
              'name': m['name'] ?? '',
              'phone': m['phone'],
              'party_type': m['partyType'] ?? 'customer',
              'current_balance':
                  (m['currentBalance'] as num?)?.toDouble() ?? 0.0,
              'credit_limit': (m['creditLimit'] as num?)?.toDouble() ?? 0.0,
              'data_json': jsonEncode(m),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Upsert Ledger Entries
      if (data['entries'] is List) {
        batch.delete('ledger_entries');
        for (final item in data['entries']) {
          final m = Map<String, dynamic>.from(item);
          batch.insert(
            'ledger_entries',
            {
              'id': m['id'] ?? '',
              'party_id': m['partyId'] ?? '',
              'amount': (m['amount'] as num?)?.toDouble() ?? 0.0,
              'entry_type': m['entryType'] ?? 'credit',
              'running_balance':
                  (m['runningBalance'] as num?)?.toDouble() ?? 0.0,
              'created_at': m['createdAt'] ?? DateTime.now().toIso8601String(),
              'data_json': jsonEncode(m),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Upsert Orders
      if (data['orders'] is List) {
        batch.delete('orders');
        for (final item in data['orders']) {
          final m = Map<String, dynamic>.from(item);
          batch.insert(
            'orders',
            {
              'id': m['id'] ?? '',
              'customer_party_id': m['customerPartyId'],
              'total_amount': (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
              'cash_received': (m['cashReceived'] as num?)?.toDouble() ?? 0.0,
              'online_received':
                  (m['onlineReceived'] as num?)?.toDouble() ?? 0.0,
              'credit_amount': (m['creditAmount'] as num?)?.toDouble() ?? 0.0,
              'created_at': m['createdAt'] ?? DateTime.now().toIso8601String(),
              'data_json': jsonEncode(m),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Upsert Metadata / App Settings
      final metadataKeys = [
        'activeShopId',
        'hasCompletedOnboarding',
        'security',
        'googleDrive',
        'notifications'
      ];
      for (final key in metadataKeys) {
        if (data.containsKey(key)) {
          batch.insert(
            'app_metadata',
            {
              'key': key,
              'value_json': jsonEncode(data[key]),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
    });
  }

  // 4. Backup & Restore Helpers (Directly Querying SQLite in-memory without any disk JSON file)
  Future<String> exportDatabaseJson() async {
    await persistToDisk();
    try {
      final Map<String, dynamic> data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'activeShopId': ShopState.instance.activeShopId,
        'hasCompletedOnboarding': ShopState.instance.hasCompletedOnboarding,
        'shops': ShopState.instance.shops.map((s) => s.toMap()).toList(),
        'products': InventoryState.instance.allProductsForDatabase
            .map((p) => p.toMap())
            .toList(),
        'purchases': InventoryState.instance.allPurchasesForDatabase
            .map((p) => p.toMap())
            .toList(),
        'parties': KhataState.instance.allPartiesForDatabase
            .map((p) => p.toMap())
            .toList(),
        'entries': KhataState.instance.allEntriesForDatabase
            .map((e) => e.toMap())
            .toList(),
        'orders': KhataState.instance.allOrdersForDatabase
            .map((o) => o.toMap())
            .toList(),
        'googleDrive': GoogleDriveService.instance.toMap(),
        'notifications': NotificationService.instance.toDatabaseList(),
      };
      return jsonEncode(data);
    } catch (e) {
      debugPrint('exportDatabaseJson SQLite error: $e');
      return '{}';
    }
  }

  Future<bool> restoreDatabaseFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);
      if (data.containsKey('purchases') && data['purchases'] is! List) {
        debugPrint('Restore rejected: malformed purchases section');
        return false;
      }

      // 1. Commit directly into SQLite tables
      await _writeJsonDataIntoSqlite(data);

      // 2. Reload into active state ViewModels
      await _loadFromSqliteIntoState();
      _loadFailed = false;
      _attachListeners();
      await persistToDisk();
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    _debounceTimer?.cancel();
    _loadFailed = false;

    // Clear all SQLite tables directly
    if (_db != null && _db!.isOpen) {
      await _db!.transaction((txn) async {
        await txn.delete('shops');
        await txn.delete('products');
        await txn.delete('purchases');
        await txn.delete('parties');
        await txn.delete('ledger_entries');
        await txn.delete('orders');
        await txn.delete('app_metadata');
      });
      debugPrint('LocalDatabaseService: All SQLite tables cleared.');
    }

    InventoryState.instance.loadFromDatabase([], []);
    KhataState.instance.loadFromDatabase(parties: [], entries: [], orders: []);
    ShopState.instance.loadFromDatabase(
        shops: [], activeShopId: 'shop_1', hasCompletedOnboarding: false);
    SecurityService.instance.setLockEnabled(false, pin: '');
    NotificationService.instance.clearAll();
    _debounceTimer?.cancel();
    _attachListeners();
    _debounceTimer?.cancel();
  }
}
