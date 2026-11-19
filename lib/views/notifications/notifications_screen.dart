import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
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
    } else if (_selectedFilter == 'Khata') {
      return list.where((n) => n.type == NotificationType.paymentDue).toList();
    } else if (_selectedFilter == 'System') {
      return list
          .where((n) =>
              n.type == NotificationType.cloudBackup ||
              n.type == NotificationType.security ||
              n.type == NotificationType.saleSummary)
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
      Navigator.pushNamed(context, notif.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifService.unreadCount;
    final activeShop = ShopState.instance.activeShop;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Notifications & Alerts',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared')),
                );
              },
            ),
          ],
        ],
      ),

      body: Column(
        children: [
          // 1. System Push Notification Permission Banner
          _buildPermissionBanner(),

          // 2. Filter Tabs (All, Stock, Khata, System)
          _buildFilterTabs(),

          // 3. Notifications List
          Expanded(
            child: _filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final notif = _filteredList[index];
                      return _buildNotificationCard(notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    final granted = _notifService.hasSystemPermission;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: granted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            granted ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
            size: 18,
            color: granted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              granted
                  ? 'Real-Time Device Notifications Active'
                  : 'Phone notification permission required for background alerts',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: granted ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
            ),
          ),
          if (!granted)
            TextButton(
              onPressed: () {
                _notifService.toggleSystemPermission(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Device notifications permission granted!'),
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
              },
              child: const Text('Allow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Stock', 'Khata', 'System'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFDBEAFE),
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
              // Category Icon
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

              // Title, Message & Timestamp
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
                              color: const Color(0xFF0F172A),
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
                    if (notif.route != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _getActionLabel(notif.type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_forward, size: 12, color: iconColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Unread indicator dot
              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
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

  String _getActionLabel(NotificationType type) {
    switch (type) {
      case NotificationType.stockAlert:
        return 'Restock Karein';
      case NotificationType.paymentDue:
        return 'Khata Check Karein';
      case NotificationType.cloudBackup:
        return 'Cloud Backup Settings';
      case NotificationType.security:
        return 'Secure Terminal';
      case NotificationType.saleSummary:
        return 'View Bills';
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
          const Text(
            'Koi Naya Alert Nahi Hai',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aap ki dukan ka stock, khata, aur sales sab theek hain.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
