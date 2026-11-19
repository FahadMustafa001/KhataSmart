import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService instance = SecurityService._();
  SecurityService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // CRITICAL REQUIREMENT: By default security is completely DISABLED (false)
  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  String _pinHash = '';
  String _pinSalt = '';
  String _securityQuestion = 'What is your security keyword?';
  String _answerHash = '';
  String _answerSalt = '';
  bool _isAppUnlocked = false;

  bool get isLockEnabled => _isLockEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasPinSet => _pinHash.isNotEmpty;
  bool get isAppUnlocked => !_isLockEnabled || _isAppUnlocked;
  String get securityQuestion => _securityQuestion;
  bool get hasSecurityAnswer => _answerHash.isNotEmpty;

  // Slow-KDF / Salted Hash Helpers
  static String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Encode(bytes);
  }

  static String _hashWithSalt(String input, String salt, {int iterations = 1000}) {
    List<int> current = utf8.encode('$salt:$input');
    for (int i = 0; i < iterations; i++) {
      current = sha256.convert(current).bytes;
    }
    return base64Encode(current);
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'isLockEnabled': _isLockEnabled,
      'isBiometricEnabled': _isBiometricEnabled,
      'pinHash': _pinHash,
      'pinSalt': _pinSalt,
      'securityQuestion': _securityQuestion,
      'answerHash': _answerHash,
      'answerSalt': _answerSalt,
    };
  }

  void loadFromDatabase({
    required bool isLockEnabled,
    required bool isBiometricEnabled,
    String? pinHash,
    String? pinSalt,
    String? pin,
    String? question,
    String? answerHash,
    String? answerSalt,
    String? answer,
  }) {
    _isLockEnabled = isLockEnabled;
    _isBiometricEnabled = isBiometricEnabled;
    if (question != null && question.trim().isNotEmpty) {
      _securityQuestion = question.trim();
    }

    if (pinHash != null && pinHash.isNotEmpty && pinSalt != null && pinSalt.isNotEmpty) {
      _pinHash = pinHash;
      _pinSalt = pinSalt;
    } else if (pin != null && pin.isNotEmpty) {
      // Legacy migration
      _pinSalt = _generateSalt();
      _pinHash = _hashWithSalt(pin, _pinSalt);
    } else {
      _pinHash = '';
      _pinSalt = '';
    }

    if (answerHash != null && answerHash.isNotEmpty && answerSalt != null && answerSalt.isNotEmpty) {
      _answerHash = answerHash;
      _answerSalt = answerSalt;
    } else if (answer != null && answer.trim().isNotEmpty) {
      // Legacy migration
      _answerSalt = _generateSalt();
      _answerHash = _hashWithSalt(answer.trim().toLowerCase(), _answerSalt);
    } else {
      _answerHash = '';
      _answerSalt = '';
    }

    _isAppUnlocked = !_isLockEnabled;
    notifyListeners();
  }

  void lockApp() {
    if (_isLockEnabled) {
      _isAppUnlocked = false;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isAppUnlocked = true;
    notifyListeners();
  }

  bool verifyPin(String inputPin) {
    if (!_isLockEnabled) return true;
    if (_pinHash.isEmpty || _pinSalt.isEmpty) {
      return false;
    }
    final computed = _hashWithSalt(inputPin, _pinSalt);
    if (computed == _pinHash) {
      _isAppUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setLockEnabled(bool enabled, {required String pin, String? question, String? answer}) {
    _isLockEnabled = enabled;
    if (enabled) {
      if (pin.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
        _pinSalt = _generateSalt();
        _pinHash = _hashWithSalt(pin, _pinSalt);
      }
      if (question != null && question.trim().isNotEmpty) {
        _securityQuestion = question.trim();
      }
      if (answer != null && answer.trim().isNotEmpty) {
        _answerSalt = _generateSalt();
        _answerHash = _hashWithSalt(answer.trim().toLowerCase(), _answerSalt);
      }
      _isAppUnlocked = true;
    } else {
      _pinHash = '';
      _pinSalt = '';
      _answerHash = '';
      _answerSalt = '';
      _isBiometricEnabled = false;
      _isAppUnlocked = true;
    }
    notifyListeners();
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final available = await isBiometricHardwareAvailable();
      if (!available) {
        _isBiometricEnabled = false;
        notifyListeners();
        return false;
      }
    }
    _isBiometricEnabled = enabled;
    notifyListeners();
    return true;
  }

  bool updatePin({required String oldPin, required String newPin}) {
    if (hasPinSet && !verifyPin(oldPin)) {
      return false;
    }
    if (newPin.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(newPin)) {
      _pinSalt = _generateSalt();
      _pinHash = _hashWithSalt(newPin, _pinSalt);
      notifyListeners();
      return true;
    }
    return false;
  }

  bool resetPinWithSecurityAnswer({
    required String answer,
    required String newPin,
  }) {
    if (!_isLockEnabled) return false;
    if (_answerHash.isEmpty || _answerSalt.isEmpty) {
      return false;
    }
    if (newPin.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(newPin)) {
      return false;
    }
    final normalized = answer.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final computed = _hashWithSalt(normalized, _answerSalt);
    if (computed == _answerHash) {
      _pinSalt = _generateSalt();
      _pinHash = _hashWithSalt(newPin, _pinSalt);
      _isAppUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setSecurityQuestion({
    required String question,
    required String answer,
  }) {
    _securityQuestion = question.trim();
    if (answer.trim().isNotEmpty) {
      _answerSalt = _generateSalt();
      _answerHash = _hashWithSalt(answer.trim().toLowerCase(), _answerSalt);
    }
    notifyListeners();
  }

  // Check if physical device supports fingerprint or face biometrics and has enrollments
  Future<bool> isBiometricHardwareAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!isSupported && !canCheck) return false;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Real Hardware Biometric Authentication (Never simulated)
  Future<bool> authenticateWithBiometrics() async {
    try {
      final available = await isBiometricHardwareAvailable();
      if (!available) {
        return false;
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Scan your Fingerprint or Face to unlock SmartKhata',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuth) {
        _isAppUnlocked = true;
        notifyListeners();
      }
      return didAuth;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
}
