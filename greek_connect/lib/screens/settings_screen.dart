import 'package:flutter/material.dart';
import '../services/local_notification_service.dart';

class gcSettingsScreen extends StatefulWidget {
  const gcSettingsScreen({super.key});

  @override
  State<gcSettingsScreen> createState() => _gcSettingsScreenState();
}

class _gcSettingsScreenState extends State<gcSettingsScreen> {
  // Notification type toggles
  bool newEvents = true;
  bool myUpcomingEvents = true;
  bool houseUpdates = false;
  bool urgentUpdates = true;

  // Notification method toggles
  bool outlook = true;
  bool textMessages = false;
  bool _isTestingNotification = false;

  Future<void> _sendTestNotification() async {
    if (_isTestingNotification) return;

    setState(() => _isTestingNotification = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await gcLocalNotificationService.instance
          .scheduleTestNotification();

      String message;
      switch (result) {
        case gcReminderScheduleResult.scheduledExact:
          message = 'Test notification scheduled for ~10 seconds from now.';
          break;
        case gcReminderScheduleResult.scheduledInexact:
          message =
              'Test notification scheduled (approximate timing due to Android alarm settings).';
          break;
        case gcReminderScheduleResult.skippedNoPermission:
          message =
              'Notifications are disabled. Enable app notifications in system settings.';
          break;
        case gcReminderScheduleResult.skippedWeb:
          message = 'Local notifications are not supported on web in this app.';
          break;
        case gcReminderScheduleResult.skippedTooSoon:
          message = 'Notification test was skipped.';
          break;
      }

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to schedule test notification: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isTestingNotification = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'I want to be notified of:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            CheckboxListTile(
              title: const Text('New Events'),
              value: newEvents,
              onChanged: (value) {
                setState(() {
                  newEvents = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('My Upcoming Events'),
              value: myUpcomingEvents,
              onChanged: (value) {
                setState(() {
                  myUpcomingEvents = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('House Updates'),
              value: houseUpdates,
              onChanged: (value) {
                setState(() {
                  houseUpdates = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Urgent Updates'),
              value: urgentUpdates,
              onChanged: (value) {
                setState(() {
                  urgentUpdates = value!;
                });
              },
            ),

            const Divider(height: 40, thickness: 2),

            const Text(
              'I want to be notified through:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            CheckboxListTile(
              title: const Text('Outlook'),
              value: outlook,
              onChanged: (value) {
                setState(() {
                  outlook = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Text Messages'),
              value: textMessages,
              onChanged: (value) {
                setState(() {
                  textMessages = value!;
                });
              },
            ),

            const Divider(height: 40, thickness: 2),

            const Text(
              'Local Notification Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isTestingNotification ? null : _sendTestNotification,
              icon: _isTestingNotification
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active),
              label: Text(
                _isTestingNotification
                    ? 'Scheduling Test Notification...'
                    : 'Send Test Notification (10s)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
