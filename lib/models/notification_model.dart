enum NotificationType {
  stockAlert,
  paymentDue,
  saleSummary,
  cloudBackup,
  security,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final String? route;
  final String? referenceId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.route,
    this.referenceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'route': route,
      'referenceId': referenceId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    NotificationType type;
    try {
      type = NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.stockAlert,
      );
    } catch (_) {
      type = NotificationType.stockAlert;
    }

    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: type,
      timestamp: map['timestamp'] != null
          ? (DateTime.tryParse(map['timestamp']) ?? DateTime.now())
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      route: map['route'],
      referenceId: map['referenceId'],
    );
  }
}
