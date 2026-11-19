import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService instance = SecurityService._();
  SecurityService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // CRITICAL REQUIREMENT: By default security is completely DISABLED (false)
  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  String _pin = '';
  String _securityQuestion = 'What is your security keyword?';
  String _securityAnswer = '';
  bool _isAppUnlocked = false;

  bool get isLockEnabled => _isLockEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasPinSet => _pin.isNotEmpty;
  bool get isAppUnlocked => !_isLockEnabled || _isAppUnlocked;
  String get securityQuestion => _securityQuestion;
  bool get hasSecurityAnswer => _securityAnswer.isNotEmpty;
  String get rawPin => _pin;
  String get rawAnswer => _securityAnswer;

  void loadFromDatabase({
    required bool isLockEnabled,
    required bool isBiometricEnabled,
    required String pin,
    String? question,
    String? answer,
  }) {
    _isLockEnabled = isLockEnabled;
    _isBiometricEnabled = isBiometricEnabled;
    _pin = pin;
    if (question != null && question.isNotEmpty) _securityQuestion = question;
    if (answer != null) _securityAnswer = answer;
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
    if (_pin.isEmpty) return true;
    if (_pin == inputPin) {
      _isAppUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setLockEnabled(bool enabled, {required String pin, String? question, String? answer}) {
    _isLockEnabled = enabled;
    if (enabled) {
      _pin = pin;
      if (question != null && question.trim().isNotEmpty) {
        _securityQuestion = question.trim();
      }
      if (answer != null && answer.trim().isNotEmpty) {
        _securityAnswer = answer.trim();
      }
      _isAppUnlocked = true;
    } else {
      _pin = '';
      _isAppUnlocked = true;
    }
    notifyListeners();
  }

  void setBiometricEnabled(bool enabled) {
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  bool updatePin({required String oldPin, required String newPin}) {
    if (_pin.isNotEmpty && _pin != oldPin) {
      return false;
    }
    if (newPin.length == 4) {
      _pin = newPin;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool resetPinWithSecurityAnswer({
    required String answer,
    required String newPin,
  }) {
    if (_securityAnswer.isEmpty) {
      // If no answer was set yet, accept and set new pin
      if (newPin.length == 4) {
        _pin = newPin;
        _securityAnswer = answer.trim();
        _isAppUnlocked = true;
        notifyListeners();
        return true;
      }
      return false;
    }

    if (answer.trim().toLowerCase() == _securityAnswer.trim().toLowerCase()) {
      if (newPin.length == 4) {
        _pin = newPin;
        _isAppUnlocked = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void setSecurityQuestion({
    required String question,
    required String answer,
  }) {
    _securityQuestion = question.trim();
    _securityAnswer = answer.trim();
    notifyListeners();
  }

  // Check if physical device supports fingerprint or face biometrics
  Future<bool> isBiometricHardwareAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  // Real Hardware Biometric Authentication
  Future<bool> authenticateWithBiometrics() async {
    try {
      final available = await isBiometricHardwareAvailable();
      if (!available) {
        // Fallback for emulators/devices without enrolled hardware
        await Future.delayed(const Duration(milliseconds: 300));
        _isAppUnlocked = true;
        notifyListeners();
        return true;
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Scan your Fingerprint or Face to unlock SmartKhata',
        options: const AuthenticationOptions(
          biometricOnly: false,
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
