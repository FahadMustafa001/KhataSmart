import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/party_model.dart';
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
              'Your shop data has been safely backed up to Google Drive (${drive.formattedBackupSize}).',
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
                    ? 'This item is completely out of stock! Please restock immediately.'
                    : 'Only ${p.stockQty} ${p.unit} remaining in stock. Please place a reorder.',
            type: NotificationType.stockAlert,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            route: AppRoutes.inventoryList,
            referenceId: p.id,
          ),
        );
      }
    }

    // 2. Pending Khata Debtors & Credit Limit Breach
    for (final c in debtors) {
      // Check credit limit breach first
      if (c.creditLimit != null && c.creditLimit! > 0 && c.balance > c.creditLimit!) {
        final breachExists = _notifications.any(
          (n) => n.type == NotificationType.creditLimitBreach && n.referenceId == c.id,
        );
        if (!breachExists) {
          _notifications.insert(
            0,
            NotificationModel(
              id: 'notif_limit_${c.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: '⚠️ Credit Limit Exceeded: ${c.name}',
              message:
                  'Warning: ${c.name}\'s credit balance (PKR ${c.balance.toStringAsFixed(0)}) has exceeded their approved limit (PKR ${c.creditLimit!.toStringAsFixed(0)})!',
              type: NotificationType.creditLimitBreach,
              timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
              route: AppRoutes.partyLedgerDetail,
              referenceId: c.id,
            ),
          );
        }
      }

      // Regular debtor alert
      final exists = _notifications.any(
        (n) => (n.type == NotificationType.paymentDue || n.type == NotificationType.creditLimitBreach) && n.referenceId == c.id,
      );
      if (!exists) {
        _notifications.insert(
          0,
          NotificationModel(
            id: 'notif_khata_${c.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Payment Due: ${c.name}',
            message:
                'PKR ${c.balance.toStringAsFixed(0)} pending receivable (${c.displayLocation.isNotEmpty ? c.displayLocation : "Customer Ledger"}). Send a payment reminder.',
            type: NotificationType.paymentDue,
            timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
            route: AppRoutes.partyLedgerDetail,
            referenceId: c.id,
          ),
        );
      }
    }

    // 3. Daily Sales & Profit Closing Alert
    final orders = KhataState.instance.orders;
    final now = DateTime.now();
    final todayOrders = orders.where((o) =>
      o.date.year == now.year &&
      o.date.month == now.month &&
      o.date.day == now.day
    ).toList();

    if (todayOrders.isNotEmpty) {
      final totalSales = todayOrders.fold(0.0, (sum, o) => sum + o.total);
      final totalCost = todayOrders.fold(0.0, (sum, o) =>
        sum + o.items.fold(0.0, (isum, i) => isum + (i.costPriceAtSale * i.quantity))
      );
      final netProfit = totalSales - totalCost;
      final todayDateStr = '${now.year}-${now.month}-${now.day}';

      final existingIndex = _notifications.indexWhere(
        (n) => n.type == NotificationType.saleSummary && n.referenceId == todayDateStr,
      );

      final message =
          'Today\'s Sales Summary: Gross sales PKR ${totalSales.toStringAsFixed(0)}, estimated profit PKR ${netProfit.toStringAsFixed(0)} (${todayOrders.length} completed orders).';

      if (existingIndex == -1) {
        _notifications.insert(
          0,
          NotificationModel(
            id: 'notif_sales_$todayDateStr',
            title: '📊 Daily Sales & Profit Closing',
            message: message,
            type: NotificationType.saleSummary,
            timestamp: DateTime.now(),
            route: AppRoutes.reports,
            referenceId: todayDateStr,
          ),
        );
      } else {
        final old = _notifications[existingIndex];
        _notifications[existingIndex] = NotificationModel(
          id: old.id,
          title: '📊 Daily Sales & Profit Closing',
          message: message,
          type: NotificationType.saleSummary,
          timestamp: DateTime.now(),
          isRead: old.isRead,
          route: AppRoutes.reports,
          referenceId: todayDateStr,
        );
      }
    }

    // 4. Cloud Backup Due Alert (if not backed up in 3+ days or never)
    final drive = GoogleDriveService.instance;
    final lastBackup = drive.lastBackupTime;
    final isDue = lastBackup == null || DateTime.now().difference(lastBackup).inDays >= 3;
    if (isDue) {
      final exists = _notifications.any(
        (n) => n.type == NotificationType.cloudBackup && n.referenceId == 'backup_due',
      );
      if (!exists) {
        final daysMsg = lastBackup == null
            ? 'No cloud backup has been created on Google Drive yet.'
            : 'No cloud backup created in the last ${DateTime.now().difference(lastBackup).inDays} days.';
        _notifications.insert(
          0,
          NotificationModel(
            id: 'notif_backup_due_${DateTime.now().millisecondsSinceEpoch}',
            title: '☁️ Cloud Backup Due Alert',
            message: '$daysMsg Sync now to keep your shop ledger safe and secure.',
            type: NotificationType.cloudBackup,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            route: AppRoutes.settings,
            referenceId: 'backup_due',
          ),
        );
      }
    }

    // 5. Security status alert if App Lock is off
    if (!SecurityService.instance.isLockEnabled) {
      final exists = _notifications.any((n) => n.type == NotificationType.security);
      if (!exists) {
        _notifications.insert(
          0,
          NotificationModel(
            id: 'notif_sec_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Terminal Security Alert',
            message:
                'App Lock is currently OFF for "${activeShop.name}". Secure cash registers and customer ledgers with a 4-Digit PIN.',
            type: NotificationType.security,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            route: AppRoutes.settings,
          ),
        );
      }
    }

    notifyListeners();
  }

  void notifyCreditLimitBreach(PartyModel party) {
    final exists = _notifications.any(
      (n) => n.type == NotificationType.creditLimitBreach && n.referenceId == party.id && !n.isRead,
    );
    if (!exists) {
      _notifications.insert(
        0,
        NotificationModel(
          id: 'notif_limit_${party.id}_${DateTime.now().millisecondsSinceEpoch}',
          title: '⚠️ Credit Limit Exceeded: ${party.name}',
          message:
              'Warning: ${party.name}\'s credit balance (PKR ${party.balance.toStringAsFixed(0)}) has exceeded their approved limit (PKR ${party.creditLimit?.toStringAsFixed(0) ?? "0"})!',
          type: NotificationType.creditLimitBreach,
          timestamp: DateTime.now(),
          route: AppRoutes.partyLedgerDetail,
          referenceId: party.id,
        ),
      );
      notifyListeners();
      LocalDatabaseService.instance.persistToDisk();
    }
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
