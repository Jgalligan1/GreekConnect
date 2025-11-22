// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';
import '../services/event_storage.dart';
import '../screens/form_screen.dart';

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

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _loadEvents(); // Load events asynchronously
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  /// Load events from storage asynchronously
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load events from storage
      final loadedEvents = await EventStorage.loadEvents();

      setState(() {
        _events = loadedEvents;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message to user
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

  /// Normalize DateTime to remove time component
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Get events for a specific day (from in-memory cache)
  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    return _events[normalizedDay] ?? [];
  }

  /// Handle day selection
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      // Update events using ValueNotifier (efficient, doesn't rebuild calendar)
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  /// Add a new event and persist to storage
  Future<void> _addEvent(Event event) async {
    final normalizedDate = _normalizeDate(event.date);
    if (_selectedDay == null) return;

    // Update in-memory cache first (immediate UI update)
    setState(() {
      if (_events[normalizedDate] == null) {
        _events[normalizedDate] = [];
      }
      _events[normalizedDate]!.add(event);
    });

    // Update selected events if viewing this day
    if (_selectedDay != null && isSameDay(_selectedDay!, event.date)) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }

    // Persist to storage (background operation)
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

  /// Delete an event and persist to storage
  Future<void> _deleteEvent(Event event) async {
    final normalizedDate = _normalizeDate(event.date);

    // Update in-memory cache first
    setState(() {
      _events[normalizedDate]?.removeWhere((e) => e.id == event.id);
      if (_events[normalizedDate]?.isEmpty ?? false) {
        _events.remove(normalizedDate);
      }
    });

    // Update selected events if viewing this day
    if (_selectedDay != null && isSameDay(_selectedDay!, event.date)) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }

    // Persist to storage
    await EventStorage.removeEvent(normalizedDate, event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Greek Connect Calendar'),
        actions: [
          // Refresh button
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
          // Clear all button (for testing)
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

                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },

                  onDaySelected: _onDaySelected,

                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },

                  // Styling
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),

                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Event list
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
                                  if (event.description != null && event.description!.isNotEmpty)
                                  Text(event.description!),

                                  if (event.location != null && event.location!.isNotEmpty)
                                    Text("📍 ${event.location}"),

                                  if (event.startTime != null && event.endTime != null)
                                    Text("⏰ ${event.startTime!.format(context)} - ${event.endTime!.format(context)}",)
                                  else if (event.startTime != null)
                                    Text("⏰ Starts at: ${event.startTime!.format(context)}")
                                  else if (event.endTime != null)
                                    Text("⏰ Ends at: ${event.endTime!.format(context)}"),
                                ],
                              ),

                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteEvent(event),
                              ),
                              onTap: () {
                                // TODO: Navigate to event details
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

      // FAB to add events
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_selectedDay == null) return;
          final newEvent = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) =>
                  FormScreen(selectedDate: _selectedDay!),
              fullscreenDialog: true,
            ),
          );
          if (newEvent != null) {
            await _addEvent(newEvent);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
