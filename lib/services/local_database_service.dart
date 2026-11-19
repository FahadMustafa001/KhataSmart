import 'dart:async';
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
import 'google_drive_service.dart';
import 'notification_service.dart';
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
  Future<void> init({bool forceRetry = false}) async {
    if (_isInitialized && !forceRetry) return;
    _isInitialized = false;
    _loadFailed = false;

    bool loadSucceeded = false;

    try {
      final file = await _getFile();
      final tmpFile = File('${file.path}.tmp');

      // Restore from .tmp file if main file is missing after an interrupted write
      if (!await file.exists() && await tmpFile.exists()) {
        try {
          await tmpFile.rename(file.path);
        } catch (_) {
          try {
            await tmpFile.copy(file.path);
            await tmpFile.delete();
          } catch (_) {}
        }
      }

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(content);
            _loadIntoState(data);
            loadSucceeded = true;
            debugPrint('LocalDatabaseService: Loaded existing offline database successfully.');
          } catch (decodeError) {
            _loadFailed = true;
            debugPrint('Database decode failure: $decodeError. Preserving unique .corrupt copy.');
            try {
              final corruptFile = File('${file.path}.${DateTime.now().millisecondsSinceEpoch}.corrupt');
              await file.copy(corruptFile.path);
            } catch (copyErr) {
              debugPrint('Failed to preserve corrupt file: $copyErr');
            }
          }
        } else {
          loadSucceeded = true;
        }
      } else {
        loadSucceeded = true;
      }
    } catch (e) {
      _loadFailed = true;
      debugPrint('LocalDatabaseService init error: $e');
    }

    _isInitialized = true;

    if (!loadSucceeded || _loadFailed) {
      _loadFailed = true;
      return;
    }

    _attachListeners();
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    // Attach debounced reactive listeners so all future mutations auto-persist safely
    ShopState.instance.addListener(schedulePersist);
    InventoryState.instance.addListener(schedulePersist);
    KhataState.instance.addListener(schedulePersist);
    SecurityService.instance.addListener(schedulePersist);
    schedulePersist();
    NotificationService.instance.addListener(schedulePersist);
  }

  /// Parses every section into local data structures before mutating state singletons.
  void _loadIntoState(Map<String, dynamic> data) {
    List<ShopModel>? parsedShops;
    String? parsedActiveShopId;
    bool? parsedHasCompletedOnboarding;
    if (data['shops'] is List) {
      parsedShops = (data['shops'] as List)
          .map((m) => ShopModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      parsedActiveShopId = data['activeShopId'] as String?;
    }
    if (data['hasCompletedOnboarding'] is bool) {
      parsedHasCompletedOnboarding = data['hasCompletedOnboarding'] as bool;
    }

    List<ProductModel>? parsedProducts;
    if (data['products'] is List) {
      parsedProducts = (data['products'] as List)
          .map((m) => ProductModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }

    List<PartyModel>? parsedParties;
    List<LedgerEntryModel>? parsedEntries;
    List<OrderModel>? parsedOrders;
    final hasKhataData = data['parties'] is List || data['entries'] is List || data['orders'] is List;
    if (hasKhataData) {
      parsedParties = (data['parties'] as List? ?? [])
          .map((m) => PartyModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      parsedEntries = (data['entries'] as List? ?? [])
          .map((m) => LedgerEntryModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      parsedOrders = (data['orders'] as List? ?? [])
          .map((m) => OrderModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }

    Map<String, dynamic>? parsedSecurity;
    if (data['security'] is Map) {
      parsedSecurity = Map<String, dynamic>.from(data['security']);
    }

    Map<String, dynamic>? parsedGoogleDrive;
    if (data['googleDrive'] is Map) {
      parsedGoogleDrive = Map<String, dynamic>.from(data['googleDrive']);
    }

    List<dynamic>? parsedNotifications;
    if (data['notifications'] is List) {
      parsedNotifications = List<dynamic>.from(data['notifications']);
    }

    if (parsedShops != null && parsedShops.isNotEmpty) {
      ShopState.instance.loadFromDatabase(
        shops: parsedShops,
        activeShopId: parsedActiveShopId ?? parsedShops.first.id,
        hasCompletedOnboarding: parsedHasCompletedOnboarding,
      );
    }

    if (parsedProducts != null) {
      InventoryState.instance.loadFromDatabase(parsedProducts);
    }

    if (hasKhataData) {
      KhataState.instance.loadFromDatabase(
        parties: parsedParties ?? [],
        entries: parsedEntries ?? [],
        orders: parsedOrders ?? [],
      );
    }

    if (parsedSecurity != null) {
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

    if (parsedGoogleDrive != null) {
      GoogleDriveService.instance.loadFromDatabase(parsedGoogleDrive);
    }

    if (parsedNotifications != null) {
      NotificationService.instance.loadFromDatabase(parsedNotifications);
    } else {
      NotificationService.instance.init();
    }
  }

  // 3. Debouncing & Coalescing Persistence
  Timer? _debounceTimer;
  Future<void>? _activeSaveFuture;
  bool _hasPendingSave = false;
  bool _loadFailed = false;
  bool _listenersAttached = false;

  bool get loadFailed => _loadFailed;

  void schedulePersist() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      persistToDisk();
    });
  }

  Future<void> persistToDisk() {
    _debounceTimer?.cancel();

    if (_loadFailed) {
      debugPrint('LocalDatabaseService: Skipping persistToDisk because loading failed.');
      return Future.error(StateError(
        'Cannot persist to disk while database load has failed. Please restore from backup or clear data to recover.',
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

  Future<void> _performWrite() async {
    try {
      final file = await _getFile();
      final Map<String, dynamic> payload = {
        'version': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
        'activeShopId': ShopState.instance.activeShopId,
        'hasCompletedOnboarding': ShopState.instance.hasCompletedOnboarding,
        'shops': ShopState.instance.shops.map((s) => s.toMap()).toList(),
        'products': InventoryState.instance.allProductsForDatabase.map((p) => p.toMap()).toList(),
        'parties': KhataState.instance.allPartiesForDatabase.map((p) => p.toMap()).toList(),
        'entries': KhataState.instance.allEntriesForDatabase.map((e) => e.toMap()).toList(),
        'orders': KhataState.instance.allOrdersForDatabase.map((o) => o.toMap()).toList(),
        'security': SecurityService.instance.toDatabaseMap(),
        'googleDrive': GoogleDriveService.instance.toMap(),
        'notifications': NotificationService.instance.toDatabaseList(),
      };

      final jsonStr = jsonEncode(payload);

      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsString(jsonStr, flush: true);

      // Attempt atomic replacement without deleting main file first
      try {
        await tmpFile.rename(file.path);
      } catch (renameErr) {
        // Fallback for platform-specific rename locks
        if (await file.exists()) {
          await file.delete();
        }
        await tmpFile.rename(file.path);
      }
    } catch (e) {
      debugPrint('LocalDatabaseService _performWrite error: $e');
    }
  }

  // 4. Backup & Restore Helpers
  // Excludes the security section from exportDatabaseJson so Drive backups never store PIN/credentials
  Future<String> exportDatabaseJson() async {
    // Flush any pending write first
    await persistToDisk();

    final file = await _getFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        try {
          final Map<String, dynamic> data = jsonDecode(content);
          data.remove('security');
          return jsonEncode(data);
        } catch (_) {}
      }
    }
    return '{}';
  }

  Future<bool> restoreDatabaseFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);
      _loadIntoState(data);
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
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
    final tmpFile = File('${file.path}.tmp');
    if (await tmpFile.exists()) {
      await tmpFile.delete();
    }
    _attachListeners();
  }
}
