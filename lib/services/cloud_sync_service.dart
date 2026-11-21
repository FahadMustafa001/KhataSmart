import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'local_database_service.dart';

/// Cloud Firestore Backup & Live Sync Service
/// Synchronizes store data, khata ledgers, and transactions to Firebase Cloud
class CloudSyncService extends ChangeNotifier {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  Timer? _autoUploadDebounce;

  void setAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    notifyListeners();
  }

  /// Triggered automatically whenever local database changes.
  /// Debounces by 2.5 seconds to avoid flooding Firestore during fast entry.
  void scheduleAutoSync() {
    if (!_autoSyncEnabled) return;
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    _autoUploadDebounce?.cancel();
    _autoUploadDebounce = Timer(const Duration(milliseconds: 2500), () {
      uploadToCloud().then((res) {
        if (res['success'] == true) {
          debugPrint('KhataSmart Live Cloud Sync: Snapshot updated in Firestore');
        } else {
          debugPrint('KhataSmart Live Cloud Sync notice: ${res['error']}');
        }
      }).catchError((e) {
        debugPrint('KhataSmart Live Cloud Sync error: $e');
      });
    });
  }

  String get formattedLastSync {
    if (_lastSyncTime == null) return 'Never synced to Cloud';
    final dt = _lastSyncTime!;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at $hour:$min $ampm';
  }

  /// Checks if current signed-in user has an existing cloud backup
  Future<bool> hasCloudBackup() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest');
      final doc = await docRef.get();
      return doc.exists && doc.data() != null && doc.data()!['data'] != null;
    } catch (_) {
      return false;
    }
  }

  /// Uploads current store database to Cloud Firestore
  Future<Map<String, dynamic>> uploadToCloud() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Please sign in with Google or Email first'};
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final jsonContent = await LocalDatabaseService.instance.exportDatabaseJson();
      final Map<String, dynamic> data = jsonDecode(jsonContent);

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest');

      final shopsCount = (data['shops'] as List?)?.length ?? 1;
      final productsCount = (data['products'] as List?)?.length ?? 0;
      final partiesCount = (data['parties'] as List?)?.length ?? 0;
      final ordersCount = (data['orders'] as List?)?.length ?? 0;
      final purchasesCount = (data['purchases'] as List?)?.length ?? 0;

      await docRef.set({
        'data': jsonContent,
        'shopsCount': shopsCount,
        'productsCount': productsCount,
        'partiesCount': partiesCount,
        'ordersCount': ordersCount,
        'purchasesCount': purchasesCount,
        'updatedAt': FieldValue.serverTimestamp(),
        'userEmail': user.email,
        'sizeBytes': utf8.encode(jsonContent).length,
      }, SetOptions(merge: true));

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();

      final sizeKb = (utf8.encode(jsonContent).length / 1024).toStringAsFixed(1);
      return {
        'success': true,
        'size': '$sizeKb KB',
        'shops': shopsCount,
        'products': productsCount,
        'parties': partiesCount,
        'orders': ordersCount,
      };
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      debugPrint('Cloud Firestore Upload Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Restores latest store database from Cloud Firestore
  Future<Map<String, dynamic>> restoreFromCloud() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return {'success': false, 'error': 'Please sign in first to restore from Cloud'};
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest');

      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null || doc.data()!['data'] == null) {
        _isSyncing = false;
        notifyListeners();
        return {'success': false, 'error': 'No cloud backup found for this account'};
      }

      final jsonContent = doc.data()!['data'] as String;
      final ok = await LocalDatabaseService.instance.restoreDatabaseFromJson(jsonContent);

      _isSyncing = false;
      if (ok) {
        _lastSyncTime = DateTime.now();
        notifyListeners();
        final docData = doc.data()!;
        return {
          'success': true,
          'shops': docData['shopsCount'] ?? 1,
          'products': docData['productsCount'] ?? 0,
          'parties': docData['partiesCount'] ?? 0,
          'orders': docData['ordersCount'] ?? 0,
        };
      } else {
        notifyListeners();
        return {'success': false, 'error': 'Failed to parse cloud backup data'};
      }
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      debugPrint('Cloud Firestore Restore Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
