import 'package:cloud_firestore/cloud_firestore.dart';

class gcAppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? sourceEventId;
  final DateTime scheduledFor;
  final DateTime createdAt;
  final DateTime? readAt;
  final String channel;

  gcAppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.sourceEventId,
    required this.scheduledFor,
    required this.createdAt,
    this.readAt,
    this.channel = 'in_app',
  });

  bool get isRead => readAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'sourceEventId': sourceEventId,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'channel': channel,
    };
  }

  factory gcAppNotification.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return gcAppNotification.fromMap(data, fallbackId: doc.id);
  }

  factory gcAppNotification.fromMap(
    Map<String, dynamic> map, {
    String? fallbackId,
  }) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    return gcAppNotification(
      id: (map['id'] as String?) ?? fallbackId ?? '',
      userId: (map['userId'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'generic',
      title: (map['title'] as String?) ?? 'Notification',
      body: (map['body'] as String?) ?? '',
      sourceEventId: map['sourceEventId'] as String?,
      scheduledFor: parseDate(map['scheduledFor'], now),
      createdAt: parseDate(map['createdAt'], now),
      readAt: map['readAt'] == null ? null : parseDate(map['readAt'], now),
      channel: (map['channel'] as String?) ?? 'in_app',
    );
  }
}