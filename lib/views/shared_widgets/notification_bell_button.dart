import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';

class NotificationBellButton extends StatefulWidget {
  final Color color;
  final double iconSize;

  const NotificationBellButton({
    super.key,
    this.color = const Color(0xFF1E293B),
    this.iconSize = 22,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  final _notifService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_rebuild);
  }

  @override
  void dispose() {
    _notifService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifService.unreadCount;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            unread > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_rounded,
            size: widget.iconSize,
            color: unread > 0 ? const Color(0xFF2563EB) : widget.color,
          ),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
