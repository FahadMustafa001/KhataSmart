import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/party_model.dart';
import '../models/product_model.dart';
import '../state/khata_state.dart';
import '../views/auth/auth_screen.dart';
import '../views/auth/sign_up_screen.dart';
import '../views/auth/shop_setup_screen.dart';
import '../views/dashboard/home_dashboard_screen.dart';
import '../views/inventory/add_edit_product_screen.dart';
import '../views/inventory/inventory_list_screen.dart';
import '../views/khata/khata_directory_screen.dart';
import '../views/khata/party_ledger_detail_screen.dart';
import '../views/pos/checkout_settlement_screen.dart';
import '../views/pos/pos_cart_screen.dart';
import '../views/pos/pos_scanner_screen.dart';
import '../views/pos/receipt_preview_screen.dart';
import '../views/splash/splash_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/reports/reports_screen.dart';
import '../views/security/app_lock_screen.dart';
import '../views/notifications/notifications_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String signUp = '/sign-up';
  static const String shopSetup = '/shop-setup';
  static const String dashboard = '/dashboard';
  static const String posCart = '/pos-cart';
  static const String posScanner = '/pos-scanner';
  static const String checkoutSettlement = '/checkout-settlement';
  static const String receiptPreview = '/receipt-preview';
  static const String inventoryList = '/inventory-list';
  static const String addEditProduct = '/add-edit-product';
  static const String khataDirectory = '/khata-directory';
  static const String partyLedgerDetail = '/party-ledger-detail';
  static const String settings = '/settings';
  static const String reports = '/reports';
  static const String appLock = '/app-lock';
  static const String notifications = '/notifications';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case shopSetup:
        return MaterialPageRoute(builder: (_) => const ShopSetupScreen());

      case dashboard:
        return MaterialPageRoute(builder: (_) => const HomeDashboardScreen());

      case posCart:
        return MaterialPageRoute(builder: (_) => const PosCartScreen());

      case posScanner:
        return MaterialPageRoute(builder: (_) => const PosScannerScreen());

      case checkoutSettlement:
        return MaterialPageRoute(builder: (_) => const CheckoutSettlementScreen());

      case receiptPreview:
        final order = settings.arguments as OrderModel?;
        return MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(order: order));

      case inventoryList:
        return MaterialPageRoute(builder: (_) => const InventoryListScreen());

      case addEditProduct:
        if (settings.arguments is ProductModel) {
          final product = settings.arguments as ProductModel;
          return MaterialPageRoute(builder: (_) => AddEditProductScreen(existingProduct: product));
        } else if (settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) => AddEditProductScreen(initialBarcode: settings.arguments as String),
          );
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => AddEditProductScreen(
              existingProduct: map['product'] as ProductModel?,
              initialBarcode: map['barcode'] as String?,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const AddEditProductScreen());

      case khataDirectory:
        return MaterialPageRoute(builder: (_) => const KhataDirectoryScreen());

      case partyLedgerDetail:
        PartyModel? party;
        if (settings.arguments is PartyModel) {
          party = settings.arguments as PartyModel;
        } else if (settings.arguments is String) {
          final id = settings.arguments as String;
          party = KhataState.instance.allPartiesForDatabase.where((p) => p.id == id).firstOrNull;
        }
        return MaterialPageRoute(builder: (_) => PartyLedgerDetailScreen(party: party));

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());

      case AppRoutes.appLock:
        return MaterialPageRoute(builder: (_) => const AppLockScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
