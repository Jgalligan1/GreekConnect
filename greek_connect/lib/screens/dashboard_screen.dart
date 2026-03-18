// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../services/rsvp_service.dart';
import 'settings_screen.dart';
import 'organizations_screen.dart';

class gcDashboardScreen extends StatefulWidget {
  const gcDashboardScreen({super.key});

  @override
  State<gcDashboardScreen> createState() => _gcDashboardScreenState();
}

class _gcDashboardScreenState extends State<gcDashboardScreen> {
  late Future<List<gcEvent>> _upcomingRsvpEvents;

  @override
  void initState() {
    super.initState();
    _upcomingRsvpEvents = _loadUpcomingRsvpEvents();
  }

  Future<List<gcEvent>> _loadUpcomingRsvpEvents() =>
      RsvpService.getUpcomingRsvpEvents(limit: 5);

  // Sign Out Function
  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName?.trim();
    final greetingName =
        displayName != null && displayName.isNotEmpty
        ? displayName
        : currentUser?.email?.split('@').first ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  Text(
                    'Hello $greetingName, Welcome to the Dashboard!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 150),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'My Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // MY ORGANIZATIONS (NOW NAVIGABLE)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const gcOrganizationsScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'My Organizations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF801C0D),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const gcSettingsScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF801C0D),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // RIGHT COLUMN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 125),
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
                  const SizedBox(height: 25),
                  Expanded(
                    child: FutureBuilder<List<gcEvent>>(
                      future: _upcomingRsvpEvents,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(left: 10.0, right: 10),
                            child: Text(
                              'No upcoming RSVP\'d events.\nHead to the calendar to RSVP to events!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        final events = snapshot.data!;
                        return ListView.separated(
                          itemCount: events.length,
                          separatorBuilder: (context, index) => const Divider(
                            thickness: 3,
                            endIndent: 50,
                            color: Color(0xFF801C0D),
                            height: 50,
                          ),
                          itemBuilder: (context, index) {
                            final event = events[index];
                            final daysUntil = event.date
                                .difference(DateTime.now())
                                .inDays;
                            String daysLabel;
                            if (daysUntil == 0) {
                              daysLabel = 'Today';
                            } else if (daysUntil == 1) {
                              daysLabel = 'Tomorrow';
                            } else {
                              daysLabel = 'In $daysUntil days';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10,
                              ),
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
                                  if (event.startTime != null)
                                    Text(
                                      'Time: ${event.startTime!.format(context)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  if (event.location != null &&
                                      event.location!.isNotEmpty)
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
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
