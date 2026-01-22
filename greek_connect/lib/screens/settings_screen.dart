import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification type toggles
  bool newEvents = true;
  bool myUpcomingEvents = true;
  bool houseUpdates = false;
  bool urgentUpdates = true;

  // Notification method toggles
  bool outlook = true;
  bool textMessages = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
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
          ],
        ),
      ),
    );
  }
}
