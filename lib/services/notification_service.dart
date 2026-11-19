import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../routes/app_routes.dart';
import '../state/inventory_state.dart';
import '../state/khata_state.dart';
import '../state/shop_state.dart';
import 'google_drive_service.dart';
import 'local_database_service.dart';
import 'security_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final List<NotificationModel> _notifications = [];
  bool _hasSystemPermission = true;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasSystemPermission => _hasSystemPermission;

  // Initialize and attach store event listeners
  void init() {
    // Generate initial live contextual notifications if empty
    refreshContextualNotifications();

    // Listen to changes in inventory and khata to generate timely alerts
    InventoryState.instance.addListener(_onInventoryChanged);
    KhataState.instance.addListener(_onKhataChanged);
    GoogleDriveService.instance.addListener(_onDriveChanged);
  }

  void _onInventoryChanged() {
    refreshContextualNotifications();
  }

  void _onKhataChanged() {
    refreshContextualNotifications();
  }

  void _onDriveChanged() {
    final drive = GoogleDriveService.instance;
    if (drive.lastBackupTime != null) {
      final existing = _notifications.any(
        (n) =>
            n.type == NotificationType.cloudBackup &&
            n.timestamp.difference(drive.lastBackupTime!).inMinutes.abs() < 5,
      );
      if (!existing) {
        addNotification(
          title: 'Cloud Backup Complete',
          message:
              'Aap ki dukan ka mukammal data Google Drive par mehfooz ho gaya hai (${drive.formattedBackupSize}).',
          type: NotificationType.cloudBackup,
          route: AppRoutes.settings,
        );
      }
    }
  }

  // Generate real notifications based on actual shop state
  void refreshContextualNotifications() {
    final activeShop = ShopState.instance.activeShop;
    final lowStockItems = InventoryState.instance.products.where((p) => p.isLowStock || p.stockQty <= 3).toList();
    final debtors = KhataState.instance.customers.where((c) => c.balance > 0).toList();

    // 1. Low stock alerts
    for (final p in lowStockItems) {
      final exists = _notifications.any(
        (n) => n.type == NotificationType.stockAlert && n.referenceId == p.id,
      );
      if (!exists) {
        _notifications.insert(
          0,
          NotificationModel(
            id: 'notif_stock_${p.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Low Stock Alert: ${p.name}',
            message:
                p.stockQty == 0
                    ? 'Ye item mukammal khatam (Out of Stock) ho chuka hai! Naya stock shamil karein.'
                    : 'Faqat ${p.stockQty} ${p.unit} baqi reh gaye hain. Naya stock order karein.',
            type: NotificationType.stockAlert,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            route: AppRoutes.inventoryList,
            referenceId: p.id,
          ),
        );
      }
    }

    // 2. Pending Khata Debtors
    for (final c in debtors.take(3)) {
      final exists = _notifications.any(
        (n) => n.type == NotificationType.paymentDue && n.referenceId == c.id,
      );
      if (!exists) {
        _notifications.insert(
          0,
          NotificationModel(
            id: 'notif_khata_${c.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Udhaar Wasooli: ${c.name}',
            message:
                'PKR ${c.balance.toStringAsFixed(0)} baqaya hain (${c.displayLocation.isNotEmpty ? c.displayLocation : "Khata Book"}). Payment reminder bheinjein.',
            type: NotificationType.paymentDue,
            timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
            route: AppRoutes.khataDirectory,
            referenceId: c.id,
          ),
        );
      }
    }

    // 3. Security status alert if App Lock is off
    if (!SecurityService.instance.isLockEnabled) {
      final exists = _notifications.any((n) => n.type == NotificationType.security);
      if (!exists) {
        _notifications.insert(
          0,
          NotificationModel(
            id: 'notif_sec_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Terminal Security Alert',
            message:
                'Aap ki dukan "${activeShop.name}" ka App Lock filhal OFF hai. Cash aur Khata ko 4-Digit PIN se secure karein.',
            type: NotificationType.security,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            route: AppRoutes.settings,
          ),
        );
      }
    }

    notifyListeners();
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? route,
    String? referenceId,
  }) {
    _notifications.insert(
      0,
      NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        route: route,
        referenceId: referenceId,
      ),
    );
    notifyListeners();
    LocalDatabaseService.instance.persistToDisk();
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      notifyListeners();
      LocalDatabaseService.instance.persistToDisk();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    LocalDatabaseService.instance.persistToDisk();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    LocalDatabaseService.instance.persistToDisk();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
    LocalDatabaseService.instance.persistToDisk();
  }

  void toggleSystemPermission(bool granted) {
    _hasSystemPermission = granted;
    notifyListeners();
  }

  // Database serialization
  List<Map<String, dynamic>> toDatabaseList() {
    return _notifications.map((n) => n.toMap()).toList();
  }

  void loadFromDatabase(List<dynamic> list) {
    _notifications.clear();
    for (final item in list) {
      if (item is Map) {
        _notifications.add(NotificationModel.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    if (_notifications.isEmpty) {
      refreshContextualNotifications();
    }
    notifyListeners();
  }
}
