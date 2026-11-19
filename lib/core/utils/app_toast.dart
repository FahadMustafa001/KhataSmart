import 'package:flutter/material.dart';

/// Modern Floating Pill Toast for KhataSmart
/// Replaces standard harsh square SnackBars with sleek floating island notifications.
class AppToast {
  AppToast._();

  static void showSuccess(BuildContext context, String message, {String? title}) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.check_circle_rounded,
      accentColor: const Color(0xFF22C55E),
      badgeBgColor: const Color(0xFF14532D),
    );
  }

  static void showError(BuildContext context, String message, {String? title}) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.error_outline_rounded,
      accentColor: const Color(0xFFEF4444),
      badgeBgColor: const Color(0xFF7F1D1D),
    );
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.info_outline_rounded,
      accentColor: const Color(0xFF38BDF8),
      badgeBgColor: const Color(0xFF0C4A6E),
    );
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.warning_amber_rounded,
      accentColor: const Color(0xFFFBBF24),
      badgeBgColor: const Color(0xFF78350F),
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    String? title,
    required IconData icon,
    required Color accentColor,
    required Color badgeBgColor,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        duration: const Duration(milliseconds: 2500),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Deep Slate
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: badgeBgColor.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty) ...[
                      Text(
                        title,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
