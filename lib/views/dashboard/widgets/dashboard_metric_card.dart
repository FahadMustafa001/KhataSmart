import 'package:flutter/material.dart';

class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.gradientColors,
    this.badgeText,
    this.badgeBg,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGradient = gradientColors != null && gradientColors!.isNotEmpty;
    final primaryColor =
        iconColor ?? (isGradient ? Colors.white : const Color(0xFF16A34A));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isGradient ? null : (backgroundColor ?? const Color(0xFFF0FDF4)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isGradient
                  ? Colors.transparent
                  : (borderColor ?? const Color(0xFFBBF7D0)),
            ),
            gradient: isGradient
                ? LinearGradient(
                    colors: gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: isGradient
                ? [
                    BoxShadow(
                      color: gradientColors!.first.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isGradient ? Colors.white70 : primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isGradient
                          ? Colors.white.withValues(alpha: 0.2)
                          : (badgeBg ?? const Color(0xFFDCFCE7)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        size: 14,
                        color: isGradient ? Colors.white : primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isGradient ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              if (badgeText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isGradient
                        ? Colors.white.withValues(alpha: 0.2)
                        : (badgeBg ?? const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isGradient
                          ? Colors.white
                          : (badgeColor ?? const Color(0xFF15803D)),
                    ),
                  ),
                )
              else
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isGradient ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
