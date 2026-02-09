// lib/screens/calendar_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';
import '../services/event_storage.dart';
import '../widgets/event_form_modal.dart';
import '../widgets/event_rsvp.dart';

enum CalendarMode { edit, rsvp }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Calendar state variables
  late final ValueNotifier<List<Event>> _selectedEvents;
  Map<DateTime, List<Event>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarMode _mode = CalendarMode.edit;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _loadEvents();
  }

  // @override
  // void dispose() {
  //   _selectedEvents.dispose();
  //   super.dispose();
  // }

  // Sign Out Function
  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  // Normalize DateTime to remove time component
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // Load events from storage
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final loadedEvents = await EventStorage.loadEvents();
      setState(() {
        _events = loadedEvents;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get events for a specific day
  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    return _events[normalizedDay] ?? [];
  }

  // Handle day selection
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  // Add event
  Future<void> _addEvent(Event event) async {
    final normalizedDate = _normalizeDate(event.date);
    if (_selectedDay == null) return;

    setState(() {
      _events.putIfAbsent(normalizedDate, () => []);
      _events[normalizedDate]!.add(event);
    });

    if (_selectedDay != null && isSameDay(_selectedDay!, event.date)) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }

    final success = await EventStorage.addEvent(normalizedDate, event);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save event'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete event
  Future<void> _deleteEvent(Event event) async {
    final normalizedDate = _normalizeDate(event.date);
    setState(() {
      _events[normalizedDate]?.removeWhere((e) => e.id == event.id);
      if (_events[normalizedDate]?.isEmpty ?? false) {
        _events.remove(normalizedDate);
      }
    });

    if (_selectedDay != null && isSameDay(_selectedDay!, event.date)) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }

    await EventStorage.removeEvent(normalizedDate, event);
  }

  // Edit event
  Future<void> _editEvent(Event oldEvent, Event updatedEvent) async {
    final oldDate = _normalizeDate(oldEvent.date);
    final newDate = _normalizeDate(updatedEvent.date);

    setState(() {
      _events[oldDate]?.removeWhere((e) => e.id == oldEvent.id);
      if (_events[oldDate]?.isEmpty ?? false) {
        _events.remove(oldDate);
      }

      _events.putIfAbsent(newDate, () => []);
      final newIndex =
          _events[newDate]!.indexWhere((e) => e.id == oldEvent.id);
      if (newIndex == -1) {
        _events[newDate]!.add(updatedEvent);
      } else {
        _events[newDate]![newIndex] = updatedEvent;
      }
    });

    if (_selectedDay != null) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }

    await EventStorage.updateEvent(oldDate, oldEvent, updatedEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Greek Connect Calendar'),
        backgroundColor: _mode == CalendarMode.rsvp ? Colors.red : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<CalendarMode>(
                    segments: const [
                      ButtonSegment(
                        value: CalendarMode.edit,
                        label: Text('Edit'),
                        icon: Icon(Icons.edit),
                      ),
                      ButtonSegment(
                        value: CalendarMode.rsvp,
                        label: Text('RSVP'),
                        icon: Icon(Icons.event_available),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) {
                      setState(() => _mode = selection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Events?'),
                  content: const Text(
                    'This will delete all events. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await EventStorage.clearAllEvents();
                _loadEvents();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<Event>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() => _calendarFormat = format);
                    }
                  },

                  // Styling
                  calendarStyle: CalendarStyle(
                    cellPadding: const EdgeInsets.only(top: 2, left: 2),
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),

                  // Show number of events instead of event titles
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final normalizedDay = DateTime.utc(
                        date.year,
                        date.month,
                        date.day,
                      );
                      final eventsForDay = _events[normalizedDay] ?? [];
                      if (eventsForDay.isEmpty) return const SizedBox.shrink();

                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${eventsForDay.length} ${eventsForDay.length == 1 ? "event" : "events"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Event list below
                Expanded(
                  child: ValueListenableBuilder<List<Event>>(
                    valueListenable: _selectedEvents,
                    builder: (context, events, _) {
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
                                'No events for this day',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
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
                                  if (event.startTime != null &&
                                      event.endTime != null)
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
                                ],
                              ),
                              trailing: _mode == CalendarMode.edit
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteEvent(event),
                                    )
                                  : null,
                              onTap: _mode == CalendarMode.edit
                                  ? () async {
                                      final updated =
                                          await showModalBottomSheet<Event>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => LayoutBuilder(
                                          builder: (context, constraints) {
                                            final maxWidth =
                                                constraints.maxWidth < 700
                                                    ? constraints.maxWidth
                                                    : 640.0;
                                            return Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                constraints: BoxConstraints(
                                                  maxWidth: maxWidth,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor,
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 16,
                                                      offset: Offset(0, -6),
                                                    ),
                                                  ],
                                                ),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.8,
                                                child: EventFormModal(
                                                  selectedDate: event.date,
                                                  initialEvent: event,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );

                                      if (updated != null) {
                                        await _editEvent(event, updated);
                                      }
                                    }
                                  : _mode == CalendarMode.rsvp
                                      ? () async {
                                          final didRsvp =
                                              await showModalBottomSheet<bool>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                EventRsvpModal(event: event),
                                          );

                                          if (didRsvp == true && mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('RSVP saved'),
                                              ),
                                            );
                                          }
                                        }
                                      : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _mode == CalendarMode.edit
          ? FloatingActionButton(
              onPressed: () async {
                if (_selectedDay == null) return;

                final newEvent = await showModalBottomSheet<Event>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth < 700
                          ? constraints.maxWidth
                          : 640.0;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 16,
                                offset: Offset(0, -6),
                              ),
                            ],
                          ),
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: EventFormModal(selectedDate: _selectedDay!),
                        ),
                      );
                    },
                  ),
                );

                if (newEvent != null) {
                  await _addEvent(newEvent);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
