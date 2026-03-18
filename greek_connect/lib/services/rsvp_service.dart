// lib/services/rsvp_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'event_storage.dart';

class RsvpService {
  /// Returns upcoming RSVPd events for the current user, sorted soonest first.
  /// Pass [limit] to cap the result set (e.g. 5 for the dashboard preview).
  static Future<List<gcEvent>> getUpcomingRsvpEvents({int? limit}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final allEventsMap = await gcEventStorage.loadEvents();
      final allEvents = allEventsMap.values.expand((list) => list).toList();

      final rsvpsSnapshot = await FirebaseFirestore.instance
          .collection('rsvps')
          .where('userId', isEqualTo: user.uid)
          .get();

      final rsvpEventIds = {
        for (final doc in rsvpsSnapshot.docs) doc['eventId'] as String,
      };

      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);

      final upcoming = allEvents
          .where((event) => rsvpEventIds.contains(event.id))
          .where(
            (event) =>
                event.date.isAfter(todayUtc) ||
                event.date.isAtSameMomentAs(todayUtc),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return limit != null ? upcoming.take(limit).toList() : upcoming;
    } catch (e) {
      print('Error loading upcoming RSVP events: $e');
      return [];
    }
  }
}
