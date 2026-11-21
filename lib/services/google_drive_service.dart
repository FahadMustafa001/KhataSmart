import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'local_database_service.dart';

/// Authenticated HTTP Client adapter for Google Drive API
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Real Google Drive Cloud Backup Service
/// Securely saves store backups to each user's personal 15 GB Google Drive
class GoogleDriveService extends ChangeNotifier {
  static final GoogleDriveService instance = GoogleDriveService._();
  GoogleDriveService._();

  static const String _backupFileName = 'KhataSmart_Backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '711388054106-7bk5k86vbl1c4vp8jqqei6eciek1tlsr.apps.googleusercontent.com'
        : null,
    serverClientId: kIsWeb
        ? null
        : '711388054106-7bk5k86vbl1c4vp8jqqei6eciek1tlsr.apps.googleusercontent.com',
    scopes: [
      drive.DriveApi.driveFileScope,
      'email',
    ],
  );

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

  /// Connects user's personal Google account with Drive scope
  Future<bool> connectAccount({String? email, String? displayName}) async {
    _isSyncing = true;
    notifyListeners();

    try {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      _isConnected = true;
      _userEmail = account.email;
      _userName = account.displayName ?? (displayName ?? account.email.split('@').first);
      _isSyncing = false;
      notifyListeners();

      await LocalDatabaseService.instance.persistToDisk();
      return true;
    } catch (e) {
      debugPrint('Google Drive connect error: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnects the active Drive account and clears cached metadata.
  Future<void> disconnectAccount() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

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

  /// Exports local database JSON payload and uploads backup to user's Google Drive.
  Future<Map<String, dynamic>> backupToDrive() async {
    _isSyncing = true;
    notifyListeners();

    try {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        _isSyncing = false;
        notifyListeners();
        return {'success': false, 'error': 'Google account is not connected'};
      }

      _isConnected = true;
      _userEmail = account.email;
      _userName = account.displayName ?? account.email.split('@').first;

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authClient);

      await LocalDatabaseService.instance.persistToDisk();
      final jsonPayload = await LocalDatabaseService.instance.exportDatabaseJson();
      final bytes = utf8.encode(jsonPayload);

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      // Search for existing file in user's Drive
      final fileList = await driveApi.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime, size)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing backup file
        final fileId = fileList.files!.first.id!;
        final fileUpdate = drive.File();
        await driveApi.files.update(
          fileUpdate,
          fileId,
          uploadMedia: media,
        );
      } else {
        // Create new backup file in Google Drive
        final newFile = drive.File()
          ..name = _backupFileName
          ..description = 'KhataSmart Store Ledger & Inventory Database Backup'
          ..mimeType = 'application/json';

        await driveApi.files.create(
          newFile,
          uploadMedia: media,
        );
      }

      _lastBackupTime = DateTime.now();
      _lastBackupSizeBytes = bytes.length;
      _isSyncing = false;
      notifyListeners();

      await LocalDatabaseService.instance.persistToDisk();

      return {
        'success': true,
        'size': formattedBackupSize,
        'timestamp': formattedLastBackup,
        'fileName': _backupFileName,
      };
    } catch (e) {
      debugPrint('Google Drive Backup Error: $e');
      _isSyncing = false;
      notifyListeners();
      return {'success': false, 'error': _formatDriveError(e)};
    }
  }

  /// Restores database state from cloud backup snapshot in user's personal Drive.
  Future<Map<String, dynamic>> restoreFromDrive() async {
    _isSyncing = true;
    notifyListeners();

    try {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        _isSyncing = false;
        notifyListeners();
        return {'success': false, 'error': 'Google account is not connected'};
      }

      _isConnected = true;
      _userEmail = account.email;
      _userName = account.displayName ?? account.email.split('@').first;

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authClient);

      final fileList = await driveApi.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime, size)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return {
          'success': false,
          'error': 'No $_backupFileName found in your Google Drive. Please create a backup first.'
        };
      }

      final file = fileList.files!.first;
      final fileId = file.id!;

      final drive.Media downloadedMedia = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> bytes = [];
      await for (final chunk in downloadedMedia.stream) {
        bytes.addAll(chunk);
      }

      final jsonContent = utf8.decode(bytes);
      final success = await LocalDatabaseService.instance.restoreDatabaseFromJson(jsonContent);

      _isSyncing = false;
      if (success) {
        _lastBackupTime = file.modifiedTime ?? DateTime.now();
        if (file.size != null) {
          _lastBackupSizeBytes = int.tryParse(file.size!) ?? bytes.length;
        } else {
          _lastBackupSizeBytes = bytes.length;
        }
        notifyListeners();
        await LocalDatabaseService.instance.persistToDisk();
        return {
          'success': true,
          'timestamp': formattedLastBackup,
        };
      } else {
        notifyListeners();
        return {
          'success': false,
          'error': 'Failed to parse database backup from Google Drive',
        };
      }
    } catch (e) {
      debugPrint('Google Drive Restore Error: $e');
      _isSyncing = false;
      notifyListeners();
      return {'success': false, 'error': _formatDriveError(e)};
    }
  }

  String _formatDriveError(dynamic e) {
    final str = e.toString();
    if (str.contains('Google Drive API has not been used') ||
        str.contains('drive.googleapis.com') ||
        (str.contains('403') && str.contains('project'))) {
      return 'Google Drive API is disabled in your Google Cloud project. Please click "ENABLE" on Google Cloud Console or use Cloud Firestore Sync above.';
    }
    return str;
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
