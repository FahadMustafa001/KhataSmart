import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/security_service.dart';
import 'state/cart_state.dart';
import 'state/inventory_state.dart';
import 'state/khata_state.dart';
import 'state/shop_state.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Mount Flutter root immediately with Hybrid MultiProvider for reactive UI
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ShopState.instance),
        ChangeNotifierProvider.value(value: InventoryState.instance),
        ChangeNotifierProvider.value(value: KhataState.instance),
        ChangeNotifierProvider.value(value: CartState.instance),
      ],
      child: const SmartKhataApp(),
    ),
  );
}

class SmartKhataApp extends StatefulWidget {
  const SmartKhataApp({super.key});

  @override
  State<SmartKhataApp> createState() => _SmartKhataAppState();
}

class _SmartKhataAppState extends State<SmartKhataApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pausedTime ??= DateTime.now();
    } else if (state == AppLifecycleState.inactive) {
      if (!SecurityService.instance.isAuthenticating) {
        _pausedTime ??= DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final pausedAt = _pausedTime!;
        _pausedTime = null;
        if (SecurityService.instance.isLockEnabled) {
          final elapsed = DateTime.now().difference(pausedAt).inSeconds;
          // Auto-lock when returning from background/idle after 5+ seconds
          if (elapsed >= 5) {
            SecurityService.instance.lockApp();
            // Verification-only screens do not suppress the mandatory lock route
            if (!SecurityService.instance.isMandatoryLockActive) {
              SecurityService.instance.isMandatoryLockActive = true;
              SecurityService.instance.isLockScreenActive = true;
              appNavigatorKey.currentState
                  ?.pushNamed(AppRoutes.appLock)
                  .then((_) {
                    SecurityService.instance.isMandatoryLockActive = false;
                    SecurityService.instance.isLockScreenActive =
                        SecurityService.instance.isVerificationLockActive;
                  });
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
