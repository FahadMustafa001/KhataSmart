import 'package:flutter/material.dart';

class AppColors {
  // Primary Navy Brand Color
  static const Color primary = Color(0xFF1A365D);
  static const Color primaryNavy = Color(0xFF1A365D);
  static const Color navyLight = Color(0xFF2A4365);
  static const Color navyDark = Color(0xFF0F172A);

  // Status & Transaction Colors
  static const Color green = Color(0xFF2E7D32); // Received / Got / Profit
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color red = Color(0xFFC62828); // Gave / Debit / Expense / Alert
  static const Color redLight = Color(0xFFFFEBEE);

  // Background & Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Dynamic Theme-Aware Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.white;

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  static Color text(BuildContext context) =>
      isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  static Color subtext(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color cardBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  static Color secondaryBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

  static Color mutedSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
}
