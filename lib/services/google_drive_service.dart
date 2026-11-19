import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_database_service.dart';

class GoogleDriveService extends ChangeNotifier {
  static final GoogleDriveService instance = GoogleDriveService._();
  GoogleDriveService._();

  bool _isConnected = false;
  String? _userEmail;
  String? _userName;
  DateTime? _lastBackupTime;
  int _lastBackupSizeBytes = 0;
  bool _isAutoBackupEnabled = false;
  bool _isSyncing = false;

  bool get isConnected => _isConnected;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  DateTime? get lastBackupTime => _lastBackupTime;
  int get lastBackupSizeBytes => _lastBackupSizeBytes;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;
  bool get isSyncing => _isSyncing;

  String get formattedLastBackup {
    if (_lastBackupTime == null) return 'Never backed up';
    final dt = _lastBackupTime!;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at $hour:$min $ampm';
  }

  String get formattedBackupSize {
    if (_lastBackupSizeBytes <= 0) return '0 KB';
    final kb = _lastBackupSizeBytes / 1024;
    if (kb > 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '${kb.toStringAsFixed(1)} KB';
  }

  // Connect Google Account for Drive Access
  Future<bool> connectAccount({required String email, String? displayName}) async {
    _isSyncing = true;
    notifyListeners();

    try {
      // Simulate real OAuth handshake latency
      await Future.delayed(const Duration(milliseconds: 700));

      _isConnected = true;
      _userEmail = email.trim();
      _userName = displayName ?? email.split('@').first;
      _isSyncing = false;
      notifyListeners();

      // Auto-save connection state in local DB
      await LocalDatabaseService.instance.persistToDisk();
      return true;
    } catch (e) {
      debugPrint('GoogleDrive connect error: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Disconnect Google Account
  Future<void> disconnectAccount() async {
    _isConnected = false;
    _userEmail = null;
    _userName = null;
    _lastBackupTime = null;
    _lastBackupSizeBytes = 0;
    _isAutoBackupEnabled = false;
    notifyListeners();

    await LocalDatabaseService.instance.persistToDisk();
  }

  void toggleAutoBackup(bool enabled) {
    _isAutoBackupEnabled = enabled;
    notifyListeners();
    LocalDatabaseService.instance.persistToDisk();
  }

  // Perform Backup to Google Drive
  Future<Map<String, dynamic>> backupToDrive() async {
    if (!_isConnected) {
      return {'success': false, 'error': 'Google Drive account is not connected'};
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Flush any pending memory changes to local database
      await LocalDatabaseService.instance.persistToDisk();

      // 2. Export complete JSON database payload
      final jsonPayload = await LocalDatabaseService.instance.exportDatabaseJson();
      final bytes = utf8.encode(jsonPayload);

      // 3. Simulate cloud upload latency to Drive folder: SmartKhata_Backups
      await Future.delayed(const Duration(milliseconds: 900));

      _lastBackupTime = DateTime.now();
      _lastBackupSizeBytes = bytes.length;
      _isSyncing = false;
      notifyListeners();

      // 4. Save metadata update to local database
      await LocalDatabaseService.instance.persistToDisk();

      return {
        'success': true,
        'size': formattedBackupSize,
        'timestamp': formattedLastBackup,
        'fileName': 'khatasmart_backup_${_lastBackupTime!.millisecondsSinceEpoch}.json',
      };
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  // Restore Database from Google Drive
  Future<Map<String, dynamic>> restoreFromDrive() async {
    if (!_isConnected) {
      return {'success': false, 'error': 'Google Drive is not linked'};
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Simulate reading latest cloud backup snapshot from Drive
      await Future.delayed(const Duration(milliseconds: 900));

      final existingJson = await LocalDatabaseService.instance.exportDatabaseJson();
      if (existingJson.isEmpty || existingJson == '{}') {
        _isSyncing = false;
        notifyListeners();
        return {'success': false, 'error': 'No backup found in Google Drive'};
      }

      // 2. Restore into memory and disk
      final success = await LocalDatabaseService.instance.restoreDatabaseFromJson(existingJson);
      _isSyncing = false;
      notifyListeners();

      return {
        'success': success,
        'timestamp': formattedLastBackup,
      };
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  // Database Serialization
  Map<String, dynamic> toMap() {
    return {
      'isConnected': _isConnected,
      'userEmail': _userEmail,
      'userName': _userName,
      'lastBackupTime': _lastBackupTime?.toIso8601String(),
      'lastBackupSizeBytes': _lastBackupSizeBytes,
      'isAutoBackupEnabled': _isAutoBackupEnabled,
    };
  }

  void loadFromDatabase(Map<String, dynamic> map) {
    _isConnected = map['isConnected'] ?? false;
    _userEmail = map['userEmail'];
    _userName = map['userName'];
    if (map['lastBackupTime'] != null) {
      _lastBackupTime = DateTime.tryParse(map['lastBackupTime']);
    }
    _lastBackupSizeBytes = (map['lastBackupSizeBytes'] as num?)?.toInt() ?? 0;
    _isAutoBackupEnabled = map['isAutoBackupEnabled'] ?? false;
    notifyListeners();
  }
}
