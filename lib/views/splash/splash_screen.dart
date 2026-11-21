import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../firebase_options.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/local_database_service.dart';
import '../../services/notification_service.dart';
import '../../services/security_service.dart';
import '../../state/shop_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Initialize local database and notification services while splash screen is visible
    await LocalDatabaseService.instance.init();
    NotificationService.instance.init();

    // 2. Initialize Firebase Core safely
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AuthService.instance.markInitialized();
    } catch (e) {
      debugPrint('Firebase init note: $e');
    }

    // 3. Minimum display time (1.2 seconds) for smooth branding display
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final hasCompletedOnboarding = ShopState.instance.hasCompletedOnboarding ||
        ShopState.instance.shops.length > 1 ||
        ShopState.instance.activeShop.phone.isNotEmpty ||
        ShopState.instance.activeShop.name != 'My Store';
    final targetRoute = hasCompletedOnboarding
        ? AppRoutes.dashboard
        : AppRoutes.auth;

    if (SecurityService.instance.isLockEnabled) {
      SecurityService.instance.lockApp();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.appLock,
        (route) => false,
        arguments: {'destinationRoute': targetRoute},
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 135,
                        height: 135,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            AppAssets.appLogo,
                            width: 135,
                            height: 135,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  color: Color(0xFF16A34A), size: 7),
                              SizedBox(width: 5),
                              Text(
                                'SYNC ON',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Smart',
                        style: TextStyle(color: Color(0xFF1A365D)),
                      ),
                      TextSpan(
                        text: 'Khata',
                        style: TextStyle(color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Smart Retail POS & Digital Ledger',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1A365D)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Initializing local database...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Offline-First Enterprise POS • Powered by SQLite & Cloud',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'v2.4.0 • 256-Bit Encrypted Ledger',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
