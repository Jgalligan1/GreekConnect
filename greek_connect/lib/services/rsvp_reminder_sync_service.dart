import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:greek_connect/models/event.dart';
import 'package:greek_connect/services/event_storage.dart';
import 'package:greek_connect/services/local_notification_service.dart';

class gcRsvpReminderSyncService {
  gcRsvpReminderSyncService._();

  static Future<void> syncForUser(String userId) async {
    try {
      final rsvpSnapshot = await FirebaseFirestore.instance
          .collection('rsvps')
          .where('userId', isEqualTo: userId)
          .get();

      if (rsvpSnapshot.docs.isEmpty) {
        debugPrint('RSVP sync: no RSVPs found for user $userId');
        return;
      }

      final rsvpByEventId = <String, Map<String, dynamic>>{};
      for (final doc in rsvpSnapshot.docs) {
        final data = doc.data();
        final eventId = data['eventId'] as String?;
        if (eventId != null && eventId.isNotEmpty) {
          rsvpByEventId[eventId] = data;
        }
      }

      if (rsvpByEventId.isEmpty) {
        debugPrint('RSVP sync: no valid event IDs found for user $userId');
        return;
      }

      final eventsMap = await gcEventStorage.loadEvents();
      final eventsById = <String, gcEvent>{};
      for (final eventsOnDay in eventsMap.values) {
        for (final event in eventsOnDay) {
          eventsById[event.id] = event;
        }
      }

      var scheduledCount = 0;
      for (final entry in rsvpByEventId.entries) {
        final eventId = entry.key;
        final rsvpData = entry.value;
        final event = eventsById[eventId];
        if (event == null || event.startTime == null) {
          continue;
        }

        final eventDate = event.date;
        final eventStartLocal = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          event.startTime!.hour,
          event.startTime!.minute,
        );

        final title = (rsvpData['title'] as String?)?.trim();
        final result = await gcLocalNotificationService.instance
            .scheduleRsvpReminder(
              eventId: eventId,
              title: (title != null && title.isNotEmpty) ? title : event.title,
              eventStartLocal: eventStartLocal,
            );

        if (result == gcReminderScheduleResult.scheduledExact ||
            result == gcReminderScheduleResult.scheduledInexact) {
          scheduledCount++;
        }
      }

      debugPrint(
        'RSVP sync complete for $userId. Scheduled reminders: $scheduledCount',
      );
    } catch (e) {
      debugPrint('RSVP reminder sync failed for $userId: $e');
    }
  }
}
