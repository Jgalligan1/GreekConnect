// lib/screens/my_events_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'settings_screen.dart';
import 'organizations_screen.dart';

class gcMyEventsScreen extends StatefulWidget {
  const gcMyEventsScreen({super.key});

  @override
  State<gcMyEventsScreen> createState() => _gcMyEventsScreenState();
}

class _RsvpInfo {
  final String userId;
  final String userName;
  final DateTime timestamp;

  _RsvpInfo({
    required this.userId,
    required this.userName,
    required this.timestamp,
  });
}

class _gcMyEventsScreenState extends State<gcMyEventsScreen> {
  late Future<List<gcEvent>> _myEvents;
  final Map<String, int> _rsvpCounts = {};

  @override
  void initState() {
    super.initState();
    _myEvents = _loadMyEvents();
  }

  Future<void> _openTopMenuDestination(String value) async {
    if (value == 'organizations') {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const gcOrganizationsScreen()),
      );
    } else if (value == 'settings') {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const gcSettingsScreen()),
      );
    }
  }

  Future<List<gcEvent>> _loadMyEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Get all events created by the current user (always fetch fresh from server)
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('userId', isEqualTo: user.uid)
          .get(const GetOptions(source: Source.server));

      final events = <gcEvent>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Ensure id is present
          data['id'] = data['id']?.toString() ?? doc.id;
          final event = gcEvent.fromJson(Map<String, dynamic>.from(data));
          events.add(event);
        } catch (e) {
          print('Error parsing event doc ${doc.id}: $e');
        }
      }

      // Sort by date (soonest first)
      events.sort((a, b) => a.date.compareTo(b.date));

      return events;
    } catch (e) {
      print('Error loading my events: $e');
      return [];
    }
  }

  Future<void> _refreshMyEvents() async {
    if (!mounted) return;
    setState(() {
      _myEvents = _loadMyEvents();
      _rsvpCounts.clear();
    });
  }

  Future<int> _getRsvpCount(String eventId) async {
    if (eventId.isEmpty) {
      return 0;
    }

    if (_rsvpCounts.containsKey(eventId)) {
      return _rsvpCounts[eventId]!;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rsvps')
          .where('eventId', isEqualTo: eventId)
          .get();
      final count = snapshot.docs.length;
      _rsvpCounts[eventId] = count;
      return count;
    } catch (e) {
      print('Error getting RSVP count: $e');
      return 0;
    }
  }

  Future<List<_RsvpInfo>> _getRsvpDetails(String eventId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rsvps')
          .where('eventId', isEqualTo: eventId)
          .orderBy('timestamp', descending: true)
          .get();

      final rsvpList = <_RsvpInfo>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final title = data['title'] as String? ?? 'Unknown';
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

        rsvpList.add(_RsvpInfo(
          userId: userId,
          userName: title,
          timestamp: timestamp,
        ));
      }
      return rsvpList;
    } catch (e) {
      print('Error getting RSVP details: $e');
      return [];
    }
  }

  void _showRsvpModal(gcEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Material(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF51539C),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${event.title} - RSVPs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<_RsvpInfo>>(
                  future: _getRsvpDetails(event.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final rsvpList = snapshot.data ?? [];
                    if (rsvpList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_off, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No one has RSVP\'d yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: rsvpList.length,
                      separatorBuilder: (context, index) => const Divider(
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final rsvp = rsvpList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF51539C),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rsvp.userName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'RSVP\'d ${_formatRsvpTime(rsvp.timestamp)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }

  String _formatRsvpTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildEventsList(List<gcEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.event_note, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No events created yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Events you create will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
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
        if (daysUntil < 0) {
          daysLabel = '${daysUntil.abs()} days ago';
        } else if (daysUntil == 0) {
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
                  'Organization: ${event.organization}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF51539C),
                  ),
                ),
              if (event.description != null && event.description!.isNotEmpty)
                Text(
                  'Description: ${event.description}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
                      : daysUntil < 0
                          ? Colors.grey
                          : Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<int>(
                future: _getRsvpCount(event.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return InkWell(
                    onTap: () => _showRsvpModal(event),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF51539C).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF51539C),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_add,
                            color: Color(0xFF51539C),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count ${count == 1 ? 'person' : 'people'} RSVP\'d',
                            style: const TextStyle(
                              color: Color(0xFF51539C),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: _openTopMenuDestination,
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'organizations',
                child: Text('Organizations'),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMyEvents,
        child: FutureBuilder<List<gcEvent>>(
          future: _myEvents,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final events = snapshot.data ?? [];
            return _buildEventsList(events);
          },
        ),
      ),
    );
  }
}
