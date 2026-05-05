// lib/services/event_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import 'notification_service.dart';

class gcEventStorage {
  static const String _key = 'events';

  // Load events from SharedPreferences
  // Returns a map where the key is a DateTime and the value is a list of Events
  static Future<Map<DateTime, List<gcEvent>>> loadEvents() async {
    final Map<DateTime, List<gcEvent>> events = {};
    try {
      // Try to load from Firestore first - always use server source for fresh data
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .get(const GetOptions(source: Source.server));

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Ensure id is present
          data['id'] = data['id'] ?? doc.id;
          final event = gcEvent.fromJson(Map<String, dynamic>.from(data));
          final normalized = _normalizeDate(event.date);
          events.putIfAbsent(normalized, () => []);
          events[normalized]!.add(event);
        } catch (e) {
          print('Error parsing event doc ${doc.id}: $e');
        }
      }

      // Persist a local cache as backup
      try {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> encodable = {};
        events.forEach((date, list) {
          encodable[date.toIso8601String()] = list
              .map((e) => e.toJson())
              .toList();
        });
        await prefs.setString(_key, json.encode(encodable));
      } catch (_) {}

      return events;
    } catch (e) {
      print('Firestore read failed, falling back to SharedPreferences: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_key);
        if (jsonString == null || jsonString.isEmpty) return {};
        final decoded = json.decode(jsonString) as Map<String, dynamic>;

        decoded.forEach((dateString, eventList) {
          final date = DateTime.parse(dateString);
          final List<gcEvent> parsedEvents = (eventList as List)
              .map(
                (eventJson) =>
                    gcEvent.fromJson(eventJson as Map<String, dynamic>),
              )
              .toList();
          events[date] = parsedEvents;
        });
        return events;
      } catch (e2) {
        print('Error loading events from SharedPreferences: $e2');
        return {};
      }
    }
  }

  // Save events to SharedPreferences
  static Future<bool> saveEvents(Map<DateTime, List<gcEvent>> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> encodable = {};

      events.forEach((date, eventList) {
        final dateString = date.toIso8601String();
        encodable[dateString] = eventList.map((e) => e.toJson()).toList();
      });

      final jsonString = json.encode(encodable);
      await prefs.setString(_key, jsonString);
      return true;
    } catch (e) {
      print('Error saving events locally: $e');
      return false;
    }
  }

  // Add an event to storage
  static Future<bool> addEvent(DateTime date, gcEvent event) async {
    final normalizedDate = _normalizeDate(date);
    try {
      // Validate required fields before saving
      if (event.organization == null || event.organization!.isEmpty) {
        print('Error: Event missing organization field');
        return false;
      }
      if (event.userId == null || event.userId!.isEmpty) {
        print('Error: Event missing userId field');
        return false;
      }

      // Log auth state for debugging
      final authUser = FirebaseAuth.instance.currentUser;
      print('DEBUG: Creating event with userId=${event.userId}');
      print('DEBUG: Current auth user uid=${authUser?.uid}');
      print('DEBUG: Auth user email=${authUser?.email}');
      print('DEBUG: IDs match: ${event.userId == authUser?.uid}');
      
      // Log what's being sent to Firestore
      final eventJson = event.toJson();
      print('DEBUG: Event JSON keys: ${eventJson.keys.toList()}');
      print('DEBUG: Event JSON organization: ${eventJson['organization']}');
      print('DEBUG: Event JSON userId: ${eventJson['userId']}');
      print('DEBUG: Event JSON: $eventJson');

      final docRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id);
      
      print('DEBUG: About to call docRef.set() with id=${event.id}');
      await docRef.set(event.toJson());
      print('DEBUG: Successfully saved event to Firestore');

      // Update local cache
      final events = await loadEvents();
      events.putIfAbsent(normalizedDate, () => []);
      events[normalizedDate]!.add(event);
      await saveEvents(events);
      return true;
    } on FirebaseException catch (e) {
      print('Error adding event to Firestore: ${e.code} - ${e.message}');
      print('Event details: organization=${event.organization}, userId=${event.userId}, title=${event.title}');
      if (e.code == 'permission-denied') {
        // Do not persist unauthorized local-only events; they appear to disappear on next sync.
        return false;
      }
      // Fall back to local-only save
      final events = await loadEvents();
      events.putIfAbsent(normalizedDate, () => []);
      events[normalizedDate]!.add(event);
      return await saveEvents(events);
    } catch (e) {
      print('Unexpected error adding event: $e');
      final events = await loadEvents();
      events.putIfAbsent(normalizedDate, () => []);
      events[normalizedDate]!.add(event);
      return await saveEvents(events);
    }
  }

  // Remove an event from storage
  static Future<bool> removeEvent(DateTime date, gcEvent event) async {
    final normalizedDate = _normalizeDate(date);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id);
      await docRef.delete();

      await NotificationService.notifyEventCancelledForRsvps(event: event);

      final events = await loadEvents();
      events[normalizedDate]?.removeWhere((e) => e.id == event.id);
      if (events[normalizedDate]?.isEmpty ?? false) {
        events.remove(normalizedDate);
      }
      await saveEvents(events);
      return true;
    } on FirebaseException catch (e) {
      print('Error removing event from Firestore: ${e.code} - ${e.message}');
      print('Event details: id=${event.id}, userId=${event.userId}, has userId? ${event.userId != null && event.userId!.isNotEmpty}');
      if (e.code == 'permission-denied') {
        // Don't remove locally if backend denied delete.
        return false;
      }
      // Fallback to local-only removal
      final events = await loadEvents();
      if (events[normalizedDate] != null) {
        events[normalizedDate]!.removeWhere((e) => e.id == event.id);
        if (events[normalizedDate]!.isEmpty) events.remove(normalizedDate);
        return await saveEvents(events);
      }
      return false;
    } catch (e) {
      print('Unexpected error removing event: $e');
      final events = await loadEvents();
      if (events[normalizedDate] != null) {
        events[normalizedDate]!.removeWhere((e) => e.id == event.id);
        if (events[normalizedDate]!.isEmpty) events.remove(normalizedDate);
        return await saveEvents(events);
      }
      return false;
    }
  }

  /// Update an existing event
  static Future<bool> updateEvent(
    DateTime date,
    gcEvent oldEvent,
    gcEvent newEvent,
  ) async {
    final normalizedDate = _normalizeDate(date);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('events')
          .doc(oldEvent.id);
      await docRef.set(newEvent.toJson());

      final events = await loadEvents();
      final index =
          events[normalizedDate]?.indexWhere((e) => e.id == oldEvent.id) ?? -1;
      if (index != -1) {
        events[normalizedDate]![index] = newEvent;
        await saveEvents(events);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating event in Firestore: $e');
      // Fallback local update
      final events = await loadEvents();
      final index =
          events[normalizedDate]?.indexWhere((e) => e.id == oldEvent.id) ?? -1;
      if (index != -1) {
        events[normalizedDate]![index] = newEvent;
        return await saveEvents(events);
      }
      return false;
    }
  }

  /// Clear all events from storage
  static Future<bool> clearAllEvents() async {
    try {
      // Delete all documents in the collection
      final coll = FirebaseFirestore.instance.collection('events');
      final snapshot = await coll.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      return true;
    } catch (e) {
      print('Error clearing events: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.remove(_key);
      } catch (_) {
        return false;
      }
    }
  }

  /// Get events for a specific date
  static Future<List<gcEvent>> getEventsForDate(DateTime date) async {
    final events = await loadEvents();
    final normalizedDate = _normalizeDate(date);
    return events[normalizedDate] ?? [];
  }

  /// Get events for a date range
  static Future<List<gcEvent>> getEventsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final events = await loadEvents();
    final List<gcEvent> rangeEvents = [];

    DateTime current = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);

    while (current.isBefore(normalizedEnd) ||
        current.isAtSameMomentAs(normalizedEnd)) {
      if (events[current] != null) {
        rangeEvents.addAll(events[current]!);
      }
      current = current.add(const Duration(days: 1));
    }

    return rangeEvents;
  }

  /// Normalize date to UTC midnight for consistent storage
  static DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
