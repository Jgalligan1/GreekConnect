import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class gcSettingsScreen extends StatefulWidget {
  const gcSettingsScreen({super.key});

  @override
  State<gcSettingsScreen> createState() => _gcSettingsScreenState();
}

class _gcSettingsScreenState extends State<gcSettingsScreen> {
  final _userService = UserService();

  bool _isLoading = true;

  // Notification type toggles
  bool newEvents = true;
  bool myUpcomingEvents = true;
  bool houseUpdates = false;
  bool urgentUpdates = true;

  // Notification method toggles
  bool outlook = true;
  bool textMessages = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    final prefs = await _userService.getNotificationPreferences(uid);
    if (mounted) {
      setState(() {
        newEvents = prefs['newEvents'] ?? true;
        myUpcomingEvents = prefs['myUpcomingEvents'] ?? true;
        houseUpdates = prefs['houseUpdates'] ?? false;
        urgentUpdates = prefs['urgentUpdates'] ?? true;
        outlook = prefs['outlook'] ?? true;
        textMessages = prefs['textMessages'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _userService.saveNotificationPreferences(uid, {
      'newEvents': newEvents,
      'myUpcomingEvents': myUpcomingEvents,
      'houseUpdates': houseUpdates,
      'urgentUpdates': urgentUpdates,
      'outlook': outlook,
      'textMessages': textMessages,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      setState(() => newEvents = value!);
                      _savePreferences();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('My Upcoming Events'),
                    value: myUpcomingEvents,
                    onChanged: (value) {
                      setState(() => myUpcomingEvents = value!);
                      _savePreferences();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('House Updates'),
                    value: houseUpdates,
                    onChanged: (value) {
                      setState(() => houseUpdates = value!);
                      _savePreferences();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Urgent Updates'),
                    value: urgentUpdates,
                    onChanged: (value) {
                      setState(() => urgentUpdates = value!);
                      _savePreferences();
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
                      setState(() => outlook = value!);
                      _savePreferences();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Text Messages'),
                    value: textMessages,
                    onChanged: (value) {
                      setState(() => textMessages = value!);
                      _savePreferences();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
