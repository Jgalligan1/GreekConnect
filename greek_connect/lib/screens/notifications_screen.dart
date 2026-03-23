import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class gcNotificationsScreen extends StatefulWidget {
  const gcNotificationsScreen({super.key});

  @override
  State<gcNotificationsScreen> createState() => _gcNotificationsScreenState();
}

class _gcNotificationsScreenState extends State<gcNotificationsScreen> {
  final UserService _userService = UserService();
  final Set<String> _pendingUnrsvpNotificationIds = <String>{};

  @override
  void initState() {
    super.initState();
    NotificationService.syncUpcomingRsvpNotificationsForCurrentUser();
  }

  Future<void> _unrsvpFromNotification(gcAppNotification item) async {
    final eventId = item.sourceEventId;
    if (eventId == null || eventId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify event for this notification.')),
      );
      return;
    }

    setState(() => _pendingUnrsvpNotificationIds.add(item.id));
    final success = await NotificationService.cancelRsvpForCurrentUser(
      eventId: eventId,
    );
    if (!mounted) return;

    setState(() => _pendingUnrsvpNotificationIds.remove(item.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'RSVP cancelled' : 'Failed to cancel RSVP'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Sign in to view notifications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<Map<String, bool>>(
        stream: _userService.watchNotificationPreferences(user.uid),
        builder: (context, prefSnapshot) {
          if (prefSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = prefSnapshot.data ?? {};
          final showUpcoming = prefs['myUpcomingEvents'] ?? true;
          final showUrgent = prefs['urgentUpdates'] ?? true;

          return StreamBuilder<List<gcAppNotification>>(
            stream: NotificationService.streamUpcomingNotificationsForCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data ?? [];
              final filteredNotifications = notifications.where((item) {
                if (item.type == 'upcoming_rsvp_event') return showUpcoming;
                if (item.type == 'event_cancelled') return showUrgent;
                return true;
              }).toList();

              if (filteredNotifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications to show',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        showUpcoming
                            ? 'RSVP to events to see them here'
                            : 'Enable upcoming notifications in Settings to see RSVP reminders',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredNotifications.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final item = filteredNotifications[index];
                  final canUnrsvp =
                    item.type == 'upcoming_rsvp_event' &&
                    (item.sourceEventId?.isNotEmpty ?? false);
                  final isUnrsvpPending =
                    _pendingUnrsvpNotificationIds.contains(item.id);
                  final daysUntil =
                      item.scheduledFor.difference(DateTime.now()).inDays;

                  String daysLabel;
                  if (daysUntil == 0) {
                    daysLabel = 'Today';
                  } else if (daysUntil == 1) {
                    daysLabel = 'Tomorrow';
                  } else if (daysUntil > 1) {
                    daysLabel = 'In $daysUntil days';
                  } else {
                    daysLabel = item.type == 'event_cancelled'
                        ? 'Recently'
                        : 'Past event';
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.type == 'event_cancelled'
                            ? const Color(0xFF801C0D)
                            : const Color(0xFF51539C),
                        child: Icon(
                          item.type == 'event_cancelled'
                              ? Icons.event_busy
                              : Icons.notifications,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.body.isNotEmpty) Text(item.body),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              daysLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: daysUntil == 0
                                    ? const Color(0xFF51539C)
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: canUnrsvp
                          ? TextButton(
                              onPressed: isUnrsvpPending
                                  ? null
                                  : () => _unrsvpFromNotification(item),
                              child: isUnrsvpPending
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Un-RSVP'),
                            )
                          : null,
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
