import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/rsvp_service.dart';

class gcNotificationsScreen extends StatefulWidget {
  const gcNotificationsScreen({super.key});

  @override
  State<gcNotificationsScreen> createState() => _gcNotificationsScreenState();
}

class _gcNotificationsScreenState extends State<gcNotificationsScreen> {
  late Future<List<gcEvent>> _upcomingRsvpEvents;

  @override
  void initState() {
    super.initState();
    _upcomingRsvpEvents = _loadUpcomingRsvpEvents();
  }

  Future<List<gcEvent>> _loadUpcomingRsvpEvents() =>
      RsvpService.getUpcomingRsvpEvents();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
      ),
      body: FutureBuilder<List<gcEvent>>(
        future: _upcomingRsvpEvents,
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
                    'Error loading events',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _upcomingRsvpEvents = _loadUpcomingRsvpEvents();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
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
                    'No upcoming events',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RSVP to events to see them here',
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
            itemCount: events.length,
            padding: const EdgeInsets.all(8),
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

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: event.colorValue,
                    child: const Icon(
                      Icons.event,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.description != null &&
                          event.description!.isNotEmpty)
                        Text(event.description!),
                      if (event.location != null &&
                          event.location!.isNotEmpty)
                        Text("📍 ${event.location}"),
                      if (event.startTime != null && event.endTime != null)
                        Text(
                          "⏰ ${event.startTime!.format(context)} - ${event.endTime!.format(context)}",
                        )
                      else if (event.startTime != null)
                        Text(
                          "⏰ Starts at: ${event.startTime!.format(context)}",
                        )
                      else if (event.endTime != null)
                        Text(
                          "⏰ Ends at: ${event.endTime!.format(context)}",
                        ),
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
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
