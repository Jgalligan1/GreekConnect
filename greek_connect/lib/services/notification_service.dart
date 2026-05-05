import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/event.dart';

class NotificationService {
  static const String _notificationsCollection = 'in_app_notifications';
  static const String _usersCollection = 'users';
  static const String _rsvpCollection = 'rsvps';
  static const String _eventsCollection = 'events';
  static const String _typeUpcomingRsvp = 'upcoming_rsvp_event';
  static const String _typeEventCancelled = 'event_cancelled';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Stream<List<gcAppNotification>> streamUpcomingNotificationsForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map(gcAppNotification.fromDoc)
              .where((item) =>
                  !item.scheduledFor.isBefore(today) ||
                  item.type == _typeEventCancelled)
              .toList();

          notifications.sort((a, b) {
            final byDate = a.scheduledFor.compareTo(b.scheduledFor);
            if (byDate != 0) return byDate;
            return a.id.compareTo(b.id);
          });

          return notifications;
        });
  }

  static Stream<Map<String, bool>> streamCurrentUserNotificationPreferences() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({});

    return _db.collection(_usersCollection).doc(user.uid).snapshots().map((doc) {
      final raw = doc.data()?['notificationPreferences'] as Map<String, dynamic>?;
      if (raw == null) return <String, bool>{};
      return raw.map((k, v) => MapEntry(k, v as bool));
    });
  }

  static Future<void> syncUpcomingRsvpNotificationsForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final rsvpSnapshot = await _db
          .collection(_rsvpCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (rsvpSnapshot.docs.isEmpty) return;

      final eventsSnapshot = await _db.collection(_eventsCollection).get();
      final eventById = <String, gcEvent>{};
      for (final doc in eventsSnapshot.docs) {
        final data = doc.data();
        data['id'] = (data['id'] as String?) ?? doc.id;
        try {
          final event = gcEvent.fromJson(Map<String, dynamic>.from(data));
          eventById[event.id] = event;
        } catch (_) {}
      }

      for (final doc in rsvpSnapshot.docs) {
        final eventId = doc.data()['eventId'] as String?;
        if (eventId == null) continue;

        final event = eventById[eventId];
        if (event == null) continue;

        await upsertUpcomingEventNotification(userId: user.uid, event: event);
      }
    } catch (e) {
      debugPrint('Error syncing RSVP notifications: $e');
    }
  }

  static Future<void> upsertUpcomingEventNotification({
    required String userId,
    required gcEvent event,
  }) async {
    final myUpcomingEnabled = await _isPreferenceEnabled(
      userId: userId,
      key: 'myUpcomingEvents',
      defaultValue: true,
    );

    final docRef = _db
        .collection(_notificationsCollection)
        .doc(_upcomingNotificationId(userId: userId, eventId: event.id));

    if (!myUpcomingEnabled) {
      await docRef.delete().catchError((_) {});
      return;
    }

    final scheduledFor = DateTime(event.date.year, event.date.month, event.date.day);
    final notification = gcAppNotification(
      id: docRef.id,
      userId: userId,
      type: _typeUpcomingRsvp,
      title: event.title,
      body: event.location == null || event.location!.isEmpty
          ? 'You RSVPd to this event.'
          : 'Location: ${event.location}',
      sourceEventId: event.id,
      scheduledFor: scheduledFor,
      createdAt: DateTime.now(),
      channel: 'in_app',
    );

    await docRef.set(notification.toMap(), SetOptions(merge: true));
  }

  static Future<bool> notifyEventCancelledForRsvps({
    required gcEvent event,
  }) async {
    try {
      final rsvpSnapshot = await _db
          .collection(_rsvpCollection)
          .where('eventId', isEqualTo: event.id)
          .get();

        if (rsvpSnapshot.docs.isEmpty) return true;

      final batch = _db.batch();
      final now = DateTime.now();

      for (final rsvpDoc in rsvpSnapshot.docs) {
        final data = rsvpDoc.data();
        final userId = data['userId'] as String?;
        if (userId == null || userId.isEmpty) continue;

        final urgentEnabled = await _isPreferenceEnabled(
          userId: userId,
          key: 'urgentUpdates',
          defaultValue: true,
        );

        final upcomingDocRef = _db
            .collection(_notificationsCollection)
            .doc(_upcomingNotificationId(userId: userId, eventId: event.id));
        batch.delete(upcomingDocRef);

        if (urgentEnabled) {
          final cancelDocRef = _db
              .collection(_notificationsCollection)
              .doc(_cancelledNotificationId(userId: userId, eventId: event.id));

          final notification = gcAppNotification(
            id: cancelDocRef.id,
            userId: userId,
            type: _typeEventCancelled,
            title: 'Event cancelled',
            body: '${event.title} was cancelled by the organizer.',
            sourceEventId: event.id,
            scheduledFor: now,
            createdAt: now,
            channel: 'in_app',
          );

          batch.set(cancelDocRef, notification.toMap(), SetOptions(merge: true));
        }

        batch.delete(rsvpDoc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error sending cancellation notifications: $e');
      return false;
    }
  }

  static Future<void> removeUpcomingEventNotification({
    required String userId,
    required String eventId,
  }) async {
    final docRef = _db
        .collection(_notificationsCollection)
        .doc(_upcomingNotificationId(userId: userId, eventId: eventId));

    try {
      await docRef.delete();
    } catch (e) {
      debugPrint('Error deleting in-app notification: $e');
    }
  }

  static Future<bool> cancelRsvpForCurrentUser({
    required String eventId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final rsvpDocRef = _db
          .collection(_rsvpCollection)
          .doc('${eventId}_${user.uid}');
      final upcomingDocRef = _db
          .collection(_notificationsCollection)
          .doc(_upcomingNotificationId(userId: user.uid, eventId: eventId));

      final batch = _db.batch();
      batch.delete(rsvpDocRef);
      batch.delete(upcomingDocRef);
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error cancelling RSVP from notifications: $e');
      return false;
    }
  }

  static String _upcomingNotificationId({
    required String userId,
    required String eventId,
  }) {
    return 'upcoming_${userId}_$eventId';
  }

  static String _cancelledNotificationId({
    required String userId,
    required String eventId,
  }) {
    return 'cancelled_${userId}_$eventId';
  }

  static Future<bool> _isPreferenceEnabled({
    required String userId,
    required String key,
    required bool defaultValue,
  }) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(userId).get();
      final raw = doc.data()?['notificationPreferences'] as Map<String, dynamic>?;
      return raw?[key] as bool? ?? defaultValue;
    } catch (e) {
      debugPrint('Error loading notification preference ($key): $e');
      return defaultValue;
    }
  }
}