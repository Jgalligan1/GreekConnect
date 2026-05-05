// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../services/event_storage.dart';
import '../services/notification_service.dart';

class gcDashboardScreen extends StatefulWidget {
  const gcDashboardScreen({super.key});
  @override
  State<gcDashboardScreen> createState() => _gcDashboardScreenState();
}

class _DashboardEventSections {
  const _DashboardEventSections({
    required this.myRsvpEvents,
    required this.upcomingEvents,
  });

  final List<gcEvent> myRsvpEvents;
  final List<gcEvent> upcomingEvents;
}

class _gcDashboardScreenState extends State<gcDashboardScreen> {
  late Future<_DashboardEventSections> _dashboardEvents;
  final Set<String> _pendingRsvpActions = <String>{};

  @override
  void initState() {
    super.initState();
    _dashboardEvents = _loadDashboardEvents();
  }

  Future<_DashboardEventSections> _loadDashboardEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _DashboardEventSections(myRsvpEvents: [], upcomingEvents: []);
    }

    try {
      // Get all events from storage
      final allEventsMap = await gcEventStorage.loadEvents();
      final allEvents = allEventsMap.values.expand((list) => list).toList();

        // Get all RSVPs for this user
      final rsvpsSnapshot = await FirebaseFirestore.instance
          .collection('rsvps')
          .where('userId', isEqualTo: user.uid)
          .get();

      final rsvpEventIds = {
        for (final doc in rsvpsSnapshot.docs) doc['eventId'] as String,
      };

      // Filter events to only those the user has RSVPd to
      final rsvpdEvents = allEvents
          .where((event) => rsvpEventIds.contains(event.id))
          .toList();

      // Filter events to those the user has not RSVPd to
      final notRsvpdEvents = allEvents
          .where((event) => !rsvpEventIds.contains(event.id))
          .toList();

      // Filter to only future events (normalize dates to UTC for consistent comparison)
      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final myUpcomingRsvpEvents = rsvpdEvents
          .where(
            (event) =>
                event.date.isAfter(todayUtc) ||
                event.date.isAtSameMomentAs(todayUtc),
          )
          .toList();

      final upcomingNonRsvpEvents = notRsvpdEvents
          .where(
            (event) =>
                event.date.isAfter(todayUtc) ||
                event.date.isAtSameMomentAs(todayUtc),
          )
          .toList();

      // Sort by date (soonest first)
      myUpcomingRsvpEvents.sort((a, b) => a.date.compareTo(b.date));
      upcomingNonRsvpEvents.sort((a, b) => a.date.compareTo(b.date));

      return _DashboardEventSections(
        myRsvpEvents: myUpcomingRsvpEvents.take(5).toList(),
        upcomingEvents: upcomingNonRsvpEvents.take(5).toList(),
      );
    } catch (e) {
      print('Error loading dashboard events: $e');
      return const _DashboardEventSections(myRsvpEvents: [], upcomingEvents: []);
    }
  }

  Future<void> _refreshDashboardEvents() async {
    if (!mounted) return;
    setState(() {
      _dashboardEvents = _loadDashboardEvents();
    });
  }

  Future<void> _rsvpToEvent(gcEvent event) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be signed in to RSVP')),
      );
      return;
    }

    final actionKey = 'rsvp_${event.id}';
    if (_pendingRsvpActions.contains(actionKey)) return;

    setState(() => _pendingRsvpActions.add(actionKey));

    try {
      final docId = '${event.id}_${user.uid}';
      await FirebaseFirestore.instance.collection('rsvps').doc(docId).set({
        'eventId': event.id,
        'userId': user.uid,
        'title': event.title,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await NotificationService.upsertUpcomingEventNotification(
        userId: user.uid,
        event: event,
      );

      messenger.showSnackBar(const SnackBar(content: Text('RSVP saved')));
      await _refreshDashboardEvents();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save RSVP: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _pendingRsvpActions.remove(actionKey));
    }
  }

  Future<void> _unRsvpFromEvent(gcEvent event) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be signed in')),
      );
      return;
    }

    final actionKey = 'unrsvp_${event.id}';
    if (_pendingRsvpActions.contains(actionKey)) return;

    setState(() => _pendingRsvpActions.add(actionKey));

    try {
      final docId = '${event.id}_${user.uid}';
      await FirebaseFirestore.instance.collection('rsvps').doc(docId).delete();

      await NotificationService.removeUpcomingEventNotification(
        userId: user.uid,
        eventId: event.id,
      );

      messenger.showSnackBar(const SnackBar(content: Text('RSVP cancelled')));
      await _refreshDashboardEvents();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to cancel RSVP: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _pendingRsvpActions.remove(actionKey));
    }
  }

  Widget _buildEventsList({
    required List<gcEvent> events,
    required String emptyMessage,
    required bool showUnRsvpAction,
  }) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10),
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (context, index) => const Divider(
        thickness: 3,
        endIndent: 50,
        color: Color(0xFF801C0D),
        height: 35,
      ),
      itemBuilder: (context, index) {
        final event = events[index];
        final daysUntil = event.date.difference(DateTime.now()).inDays;
        String daysLabel;
        if (daysUntil == 0) {
          daysLabel = 'Today';
        } else if (daysUntil == 1) {
          daysLabel = 'Tomorrow';
        } else {
          daysLabel = 'In $daysUntil days';
        }

        return Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (event.organization != null && event.organization!.isNotEmpty)
                Text(
                  'Hosted by: ${event.organization}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF51539C),
                  ),
                ),
              if (event.startTime != null)
                Text(
                  'Time: ${event.startTime!.format(context)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (event.location != null && event.location!.isNotEmpty)
                Text(
                  'Location: ${event.location}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              Text(
                daysLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: daysUntil == 0
                      ? const Color(0xFF51539C)
                      : Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showUnRsvpAction
                        ? const Color(0xFF51539C)
                        : const Color(0xFF801C0D),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _pendingRsvpActions.contains(
                        '${showUnRsvpAction ? 'unrsvp' : 'rsvp'}_${event.id}',
                      )
                      ? null
                      : () => showUnRsvpAction
                          ? _unRsvpFromEvent(event)
                          : _rsvpToEvent(event),
                  child: _pendingRsvpActions.contains(
                        '${showUnRsvpAction ? 'unrsvp' : 'rsvp'}_${event.id}',
                      )
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(showUnRsvpAction ? 'Un-RSVP' : 'RSVP'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sign Out Function
  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Hello ${FirebaseAuth.instance.currentUser!.displayName!}, Welcome to the Symposia Dashboard!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<_DashboardEventSections>(
                future: _dashboardEvents,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10),
                      child: Text(
                        'Unable to load dashboard events right now.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final sections = snapshot.data!;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 10.0),
                              child: Text(
                                'My RSVPs',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildEventsList(
                                events: sections.myRsvpEvents,
                                emptyMessage:
                                    'No upcoming RSVP\'d events.\nHead to the calendar to RSVP to events!',
                                showUnRsvpAction: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 10.0),
                              child: Text(
                                'Upcoming Events',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildEventsList(
                                events: sections.upcomingEvents,
                                emptyMessage:
                                    'No upcoming events available to RSVP right now.',
                                showUnRsvpAction: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
