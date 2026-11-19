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

  void setAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    notifyListeners();
  }

  String get formattedLastSync {
    if (_lastSyncTime == null) return 'Never synced to Cloud';
    final dt = _lastSyncTime!;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at $hour:$min $ampm';
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

      await docRef.set({
        'data': jsonContent,
        'shopsCount': (data['shops'] as List?)?.length ?? 1,
        'productsCount': (data['products'] as List?)?.length ?? 0,
        'partiesCount': (data['parties'] as List?)?.length ?? 0,
        'ordersCount': (data['orders'] as List?)?.length ?? 0,
        'purchasesCount': (data['purchases'] as List?)?.length ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'userEmail': user.email,
        'sizeBytes': utf8.encode(jsonContent).length,
      }, SetOptions(merge: true));

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();

      final sizeKb = (utf8.encode(jsonContent).length / 1024).toStringAsFixed(1);
      return {'success': true, 'size': '$sizeKb KB'};
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
        return {'success': true};
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
