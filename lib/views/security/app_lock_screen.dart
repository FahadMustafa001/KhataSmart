import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../routes/app_routes.dart';
import '../../services/security_service.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';

class AppLockScreen extends StatefulWidget {
  final bool isVerificationOnly;
  final VoidCallback? onSuccess;
  final String? destinationRoute;

  const AppLockScreen({
    super.key,
    this.isVerificationOnly = false,
    this.onSuccess,
    this.destinationRoute,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SecurityService.instance.isLockScreenActive = true;
    if (widget.isVerificationOnly) {
      SecurityService.instance.isVerificationLockActive = true;
    } else {
      SecurityService.instance.isMandatoryLockActive = true;
    }
    if (SecurityService.instance.hasCredentialError) {
      _errorMessage = 'PIN data is corrupted. Please reset your PIN below.';
    }
    // Auto-prompt biometric scan if biometric unlock is enabled
    if (SecurityService.instance.isBiometricEnabled && !SecurityService.instance.hasCredentialError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleBiometric();
      });
    }
  }

  @override
  void dispose() {
    SecurityService.instance.cancelBiometricAuth();
    if (widget.isVerificationOnly) {
      SecurityService.instance.isVerificationLockActive = false;
    } else {
      SecurityService.instance.isMandatoryLockActive = false;
    }
    SecurityService.instance.isLockScreenActive =
        SecurityService.instance.isMandatoryLockActive ||
        SecurityService.instance.isVerificationLockActive;
    super.dispose();
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  bool _hasCompletedUnlock = false;

  void _completeUnlock() {
    if (_hasCompletedUnlock) return;
    _hasCompletedUnlock = true;
    SecurityService.instance.cancelBiometricAuth();
    if (widget.isVerificationOnly) {
      SecurityService.instance.isVerificationLockActive = false;
    } else {
      SecurityService.instance.isMandatoryLockActive = false;
    }
    SecurityService.instance.isLockScreenActive =
        SecurityService.instance.isMandatoryLockActive ||
        SecurityService.instance.isVerificationLockActive;
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      final hasCompletedOnboarding = ShopState.instance.hasCompletedOnboarding ||
          ShopState.instance.shops.length > 1 ||
          ShopState.instance.activeShop.phone.isNotEmpty ||
          ShopState.instance.activeShop.name != 'My Store' ||
          InventoryState.instance.allProductsForDatabase.isNotEmpty ||
          KhataState.instance.allPartiesForDatabase.isNotEmpty;
      final destination = widget.destinationRoute ??
          (hasCompletedOnboarding ? AppRoutes.dashboard : AppRoutes.auth);
      Navigator.pushReplacementNamed(context, destination);
    }
  }

  void _verifyPin() {
    final valid = SecurityService.instance.verifyPin(_enteredPin);
    if (valid) {
      _completeUnlock();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  Future<void> _handleBiometric() async {
    final success = await SecurityService.instance.authenticateWithBiometrics();
    if (success && mounted) {
      _completeUnlock();
    }
  }

  void _showResetDialog() {
    final answerController = TextEditingController();
    final newPinController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  'Reset Security PIN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer your security question to set a new 4-digit PIN:',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Q: ${SecurityService.instance.securityQuestion}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerController,
                    decoration: InputDecoration(
                      labelText: 'Your Answer',
                      hintText: 'Enter your security answer',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New 4-Digit PIN',
                      hintText: '••••',
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dialogError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final ans = answerController.text.trim();
                  final pin = newPinController.text.trim();
                  if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
                    setDialogState(() => dialogError = 'PIN must be exactly 4 digits (0-9)');
                    return;
                  }
                  final ok = SecurityService.instance.resetPinWithSecurityAnswer(
                    answer: ans,
                    newPin: pin,
                  );
                  if (ok) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PIN reset successfully! Unlocked.'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                    _completeUnlock();
                  } else {
                    setDialogState(() => dialogError = 'Incorrect answer. Try again.');
                  }
                },
                child: const Text('Update & Unlock', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeShop = ShopState.instance.activeShop;
    final isBiometricOn = SecurityService.instance.isBiometricEnabled;

    return PopScope(
      canPop: widget.isVerificationOnly,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // 3D Padlock Security Illustration with Glow
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 26,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    AppAssets.appLockIllustration,
                    width: 92,
                    height: 92,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'KhataSmart Lock',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeShop.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // PIN Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? const Color(0xFF38BDF8) : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFF87171),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const Text(
                  'Enter 4-Digit Security PIN',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),

              const Spacer(),

              // Custom Numeric Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (isBiometricOn)
                          _buildActionButton(
                            icon: Icons.fingerprint,
                            color: const Color(0xFF38BDF8),
                            onTap: _handleBiometric,
                          )
                        else
                          const SizedBox(width: 68, height: 68),

                        _buildKeypadButton('0'),

                        _buildActionButton(
                          icon: Icons.backspace_outlined,
                          color: const Color(0xFF94A3B8),
                          onTap: _onBackspace,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: _showResetDialog,
                child: const Text(
                  'Forgot PIN? Reset Here',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  },
),
),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildKeypadButton(k)).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    return InkWell(
      onTap: () => _onKeyPress(key),
      borderRadius: BorderRadius.circular(34),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF334155)),
        ),
        alignment: Alignment.center,
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(34),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
