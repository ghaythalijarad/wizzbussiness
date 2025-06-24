class NotificationModel {
  final String id;
  final String businessId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final String priority;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      priority: json['priority'] ?? 'normal',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? businessId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    String? priority,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isHighPriority => priority == 'high' || priority == 'urgent';
  bool get isNewOrder => type == 'new_order';
  bool get isOrderUpdate => type == 'order_update';
  bool get isPaymentReceived => type == 'payment_received';
}

class NotificationSoundConfig {
  final String soundPath;
  final bool vibrate;
  final int vibrationPattern;

  NotificationSoundConfig({
    required this.soundPath,
    this.vibrate = true,
    this.vibrationPattern = 500,
  });
}

enum NotificationChannelType {
  orders,
  payments,
  general,
  urgent,
}
