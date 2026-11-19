import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/notification_model.dart';
import '../../routes/app_routes.dart';
import '../../services/google_drive_service.dart';
import '../../services/notification_service.dart';
import '../../services/printing_and_sharing_service.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifService = NotificationService.instance;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_rebuild);
    // Refresh alerts to ensure live items are up to date
    _notifService.refreshContextualNotifications();
  }

  @override
  void dispose() {
    _notifService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  List<NotificationModel> get _filteredList {
    final list = _notifService.notifications;
    if (_selectedFilter == 'Stock') {
      return list.where((n) => n.type == NotificationType.stockAlert).toList();
    } else if (_selectedFilter == 'Ledger') {
      return list
          .where((n) =>
              n.type == NotificationType.paymentDue ||
              n.type == NotificationType.creditLimitBreach)
          .toList();
    } else if (_selectedFilter == 'Sales') {
      return list.where((n) => n.type == NotificationType.saleSummary).toList();
    } else if (_selectedFilter == 'System') {
      return list
          .where((n) =>
              n.type == NotificationType.cloudBackup ||
              n.type == NotificationType.security)
          .toList();
    }
    return list;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _onNotificationTap(NotificationModel notif) {
    _notifService.markAsRead(notif.id);

    if (notif.route != null && notif.route!.isNotEmpty) {
      if (notif.route == AppRoutes.partyLedgerDetail && notif.referenceId != null) {
        Navigator.pushNamed(context, notif.route!, arguments: notif.referenceId);
      } else {
        Navigator.pushNamed(context, notif.route!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifService.unreadCount;
    final activeShop = ShopState.instance.activeShop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Notifications & Alerts',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread New',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${activeShop.name} • Live Store Alerts',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          if (_notifService.notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () => _notifService.markAllAsRead(),
              child: const Text('Read All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all, size: 22, color: Color(0xFF64748B)),
              tooltip: 'Clear All',
              onPressed: () {
                _notifService.clearAll();
                AppToast.showInfo(context, 'All notifications cleared');
              },
            ),
          ],
        ],
      ),

      body: Column(
        children: [
          _buildPermissionBanner(),
          _buildFilterTabs(),
          Expanded(
            child: _filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                    itemCount: _filteredList.length,
                    itemBuilder: (ctx, i) => _buildNotificationCard(_filteredList[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    final granted = _notifService.hasSystemPermission;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: granted ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            granted ? Icons.notifications_active : Icons.notifications_off_outlined,
            color: granted ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              granted
                  ? 'Real-Time App Notifications are Active'
                  : 'Notifications are disabled on this device',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: granted ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              ),
            ),
          ),
          if (!granted)
            TextButton(
              onPressed: () {
                _notifService.toggleSystemPermission(true);
                AppToast.showSuccess(context, 'Device notifications permission granted!');
              },
              child: const Text('Allow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Stock', 'Ledger', 'Sales', 'System'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((tab) {
            final isSelected = _selectedFilter == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(tab),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF0F172A),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedFilter = tab);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (notif.type) {
      case NotificationType.stockAlert:
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFEA580C);
        iconBg = const Color(0xFFFFF7ED);
        break;
      case NotificationType.paymentDue:
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF16A34A);
        iconBg = const Color(0xFFF0FDF4);
        break;
      case NotificationType.creditLimitBreach:
        icon = Icons.error_outline_rounded;
        iconColor = const Color(0xFFDC2626);
        iconBg = const Color(0xFFFEF2F2);
        break;
      case NotificationType.cloudBackup:
        icon = Icons.cloud_done_rounded;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEFF6FF);
        break;
      case NotificationType.security:
        icon = Icons.security_rounded;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFF5F3FF);
        break;
      case NotificationType.saleSummary:
        icon = Icons.receipt_long_rounded;
        iconColor = const Color(0xFF0891B2);
        iconBg = const Color(0xFFECFEFF);
        break;
    }

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFFEE2E2),
        child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
      ),
      onDismissed: (_) => _notifService.removeNotification(notif.id),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notif),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.type == NotificationType.creditLimitBreach
                  ? const Color(0xFFFECACA)
                  : (notif.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFDBEAFE)),
              width: notif.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: notif.type == NotificationType.creditLimitBreach
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notif.timestamp),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.message,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),

                    _buildActionButtons(notif, context),
                  ],
                ),
              ),

              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notif.type == NotificationType.creditLimitBreach
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(NotificationModel notif, BuildContext context) {
    switch (notif.type) {
      case NotificationType.creditLimitBreach:
        final partyId = notif.referenceId;
        final party = partyId != null
            ? KhataState.instance.allPartiesForDatabase.where((p) => p.id == partyId).firstOrNull
            : null;
        if (party == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  PrintingAndSharingService.instance.sendCreditLimitBreachViaWhatsApp(
                    party: party,
                    shop: ShopState.instance.activeShop,
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.white),
                label: const Text(
                  'WhatsApp Warning',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  if (party.phone.isNotEmpty) {
                    PrintingAndSharingService.instance.makePhoneCall(party.phone);
                  } else {
                    AppToast.showWarning(context, 'No phone number saved for this party');
                  }
                },
                icon: const Icon(Icons.phone_outlined, size: 13, color: Color(0xFFDC2626)),
                label: const Text(
                  'Call',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  Navigator.pushNamed(context, AppRoutes.partyLedgerDetail, arguments: party.id);
                },
                icon: const Icon(Icons.menu_book_outlined, size: 13, color: Color(0xFF475569)),
                label: const Text(
                  'View Ledger',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );

      case NotificationType.paymentDue:
        final partyId = notif.referenceId;
        final party = partyId != null
            ? KhataState.instance.allPartiesForDatabase.where((p) => p.id == partyId).firstOrNull
            : null;
        if (party == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _notifService.markAsRead(notif.id);
                    PrintingAndSharingService.instance.sendPartyLedgerViaWhatsApp(
                      party: party,
                      shop: ShopState.instance.activeShop,
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.white),
                  label: const Text(
                    'WhatsApp Reminder',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  if (party.phone.isNotEmpty) {
                    PrintingAndSharingService.instance.makePhoneCall(party.phone);
                  } else {
                    AppToast.showWarning(context, 'No phone number saved for this party');
                  }
                },
                icon: const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF2563EB)),
                label: const Text(
                  'Call',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );

      case NotificationType.stockAlert:
        final productId = notif.referenceId;
        final product = productId != null
            ? InventoryState.instance.products.where((p) => p.id == productId).firstOrNull
            : null;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (productId != null) {
                    InventoryState.instance.addStock(productId, 10);
                    _notifService.markAsRead(notif.id);
                    final updated = InventoryState.instance.products.where((p) => p.id == productId).firstOrNull;
                    AppToast.showSuccess(
                      context,
                      '+10 Stock added for "${product?.name ?? "Product"}"! New Total: ${updated?.stockQty ?? ""}',
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 13, color: Colors.white),
                label: const Text(
                  '+10 Stock Add',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  Navigator.pushNamed(context, AppRoutes.inventoryList);
                },
                icon: const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF475569)),
                label: const Text(
                  'Manage',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );

      case NotificationType.cloudBackup:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  if (!GoogleDriveService.instance.isConnected) {
                    Navigator.pushNamed(context, AppRoutes.settings);
                    AppToast.showWarning(context, 'Please link Google Drive in Settings first');
                  } else {
                    AppToast.showInfo(context, 'Starting Google Drive Backup...');
                    final res = await GoogleDriveService.instance.backupToDrive();
                    if (res['success'] == true) {
                      _notifService.markAsRead(notif.id);
                      if (context.mounted) {
                        AppToast.showSuccess(context, 'Backup completed! Size: ${res['size']}');
                      }
                    } else if (context.mounted) {
                      AppToast.showError(context, 'Backup error: ${res['error']}');
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload_outlined, size: 13, color: Colors.white),
                label: const Text(
                  'Backup Now (Drive)',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Settings', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
              ),
            ],
          ),
        );

      case NotificationType.saleSummary:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  Navigator.pushNamed(context, AppRoutes.reports);
                },
                icon: const Icon(Icons.insights_rounded, size: 13, color: Colors.white),
                label: const Text(
                  'View Financial Reports',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891B2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );

      case NotificationType.security:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _notifService.markAsRead(notif.id);
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
                icon: const Icon(Icons.lock_outline, size: 13, color: Colors.white),
                label: const Text(
                  'Enable App Lock',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            'No New Alerts',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your shop stock, customer ledgers, and sales are all up to date.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
