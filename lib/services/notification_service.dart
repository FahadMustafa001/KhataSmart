import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/party_model.dart';
import '../models/shop_model.dart';
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
  bool _listenersAttached = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasSystemPermission => _hasSystemPermission;

  // Initialize and attach store event listeners
  void init() {
    if (!_listenersAttached) {
      _listenersAttached = true;
      // Listen to changes in inventory and khata to generate timely alerts
      InventoryState.instance.addListener(_onInventoryChanged);
      KhataState.instance.addListener(_onKhataChanged);
      GoogleDriveService.instance.addListener(_onDriveChanged);
    }

    // Generate initial live contextual notifications
    refreshContextualNotifications();
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

    // 6. If notifications list is still empty, seed helpful shop baseline notifications
    if (_notifications.isEmpty) {
      _seedDefaultStoreAlerts(activeShop);
    }

    notifyListeners();
  }

  void _seedDefaultStoreAlerts(ShopModel activeShop) {
    // 1. Store System Active
    _notifications.add(
      NotificationModel(
        id: 'seed_system_${activeShop.id}',
        title: '🏪 Store System Ready: ${activeShop.name}',
        message: 'KhataSmart offline-first engine is running smoothly. Local database and encryption active.',
        type: NotificationType.security,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        route: AppRoutes.settings,
      ),
    );

    // 2. Inventory Alert or Status
    final products = InventoryState.instance.products;
    final lowStock = products.where((p) => p.isLowStock || p.stockQty <= 3).toList();
    if (lowStock.isNotEmpty) {
      final p = lowStock.first;
      _notifications.add(
        NotificationModel(
          id: 'seed_stock_${p.id}',
          title: 'Low Stock Alert: ${p.name}',
          message: p.stockQty == 0
              ? 'This item is out of stock! Tap to reorder or add stock.'
              : 'Only ${p.stockQty} ${p.unit} remaining. Restock recommended.',
          type: NotificationType.stockAlert,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          route: AppRoutes.inventoryList,
          referenceId: p.id,
        ),
      );
    } else {
      _notifications.add(
        NotificationModel(
          id: 'seed_stock_health',
          title: '📦 Inventory Tracking Active',
          message: products.isEmpty
              ? 'No products added yet. Tap to add your first product to catalog.'
              : '${products.length} product(s) tracked with safety stock thresholds.',
          type: NotificationType.stockAlert,
          timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
          route: AppRoutes.inventoryList,
        ),
      );
    }

    // 3. Khata Ledger Alert
    final customers = KhataState.instance.customers;
    final debtor = customers.where((c) => c.balance > 0).firstOrNull;
    final advanceCust = customers.where((c) => c.balance < 0).firstOrNull;

    if (debtor != null) {
      _notifications.add(
        NotificationModel(
          id: 'seed_khata_${debtor.id}',
          title: 'Payment Due: ${debtor.name}',
          message: 'PKR ${debtor.balance.toStringAsFixed(0)} pending receivable. Tap to send WhatsApp reminder.',
          type: NotificationType.paymentDue,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          route: AppRoutes.partyLedgerDetail,
          referenceId: debtor.id,
        ),
      );
    } else if (advanceCust != null) {
      _notifications.add(
        NotificationModel(
          id: 'seed_advance_${advanceCust.id}',
          title: 'Credit Advance: ${advanceCust.name}',
          message: 'Customer has advance credit balance of PKR ${advanceCust.balance.abs().toStringAsFixed(0)}.',
          type: NotificationType.paymentDue,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          route: AppRoutes.partyLedgerDetail,
          referenceId: advanceCust.id,
        ),
      );
    } else {
      _notifications.add(
        NotificationModel(
          id: 'seed_khata_guide',
          title: '📖 Udhaar Register Active',
          message: 'Customer & Supplier Ledgers ready. Send automated WhatsApp bills and payment reminders.',
          type: NotificationType.paymentDue,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          route: AppRoutes.khataDirectory,
        ),
      );
    }

    // 4. Sales Closing / POS alert
    _notifications.add(
      NotificationModel(
        id: 'seed_sales_pos',
        title: '📊 Daily Sales & Profit Closing',
        message: 'POS Counter is open. Tap to view today\'s revenue, gross margins, and settlement split.',
        type: NotificationType.saleSummary,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        route: AppRoutes.reports,
      ),
    );

    // 5. Cloud Backup Reminder
    _notifications.add(
      NotificationModel(
        id: 'seed_cloud_backup',
        title: '☁️ Google Drive Cloud Backup',
        message: 'Protect your ledger data against device loss with 1-tap Google Drive cloud backup.',
        type: NotificationType.cloudBackup,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        route: AppRoutes.settings,
        referenceId: 'backup_due',
      ),
    );
  }

  void simulateTestAlert({NotificationType? type}) {
    final t = type ?? NotificationType.stockAlert;
    final shopName = ShopState.instance.activeShop.name;
    switch (t) {
      case NotificationType.stockAlert:
        addNotification(
          title: 'Stock Warning: Fresh Milk Pack',
          message: 'Only 2 units remaining in $shopName inventory. Reorder soon.',
          type: NotificationType.stockAlert,
          route: AppRoutes.inventoryList,
        );
        break;
      case NotificationType.paymentDue:
        addNotification(
          title: 'Payment Reminder: Muhammad Tariq',
          message: 'Pending balance PKR 3,500 due for settlement.',
          type: NotificationType.paymentDue,
          route: AppRoutes.khataDirectory,
        );
        break;
      case NotificationType.creditLimitBreach:
        addNotification(
          title: '⚠️ Credit Limit Exceeded: Ali Khan',
          message: 'Current balance PKR 15,200 exceeds approved limit PKR 10,000.',
          type: NotificationType.creditLimitBreach,
          route: AppRoutes.khataDirectory,
        );
        break;
      case NotificationType.saleSummary:
        addNotification(
          title: '📈 POS Sale Completed: Bill #SK-520',
          message: 'Gross amount PKR 1,450 settled via Cash. 3 items billed.',
          type: NotificationType.saleSummary,
          route: AppRoutes.reports,
        );
        break;
      case NotificationType.cloudBackup:
        addNotification(
          title: '☁️ Cloud Backup Successful',
          message: 'All shop ledger accounts safely encrypted and backed up to Google Drive.',
          type: NotificationType.cloudBackup,
          route: AppRoutes.settings,
        );
        break;
      case NotificationType.security:
        addNotification(
          title: 'Security: Register Locked',
          message: 'Terminal app PIN verification is currently active.',
          type: NotificationType.security,
          route: AppRoutes.settings,
        );
        break;
    }
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
