// lib/services/event_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventStorage {
  static const String _key = 'events';

  // Load events from SharedPreferences
  // Returns a map where the key is a DateTime and the value is a list of Events
  static Future<Map<DateTime, List<Event>>> loadEvents() async {
    final Map<DateTime, List<Event>> events = {};
    try {
      // Try to load from Firestore first
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .get(const GetOptions(source: Source.serverAndCache));

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Ensure id is present
          data['id'] = data['id'] ?? doc.id;
          final event = Event.fromJson(Map<String, dynamic>.from(data));
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
          final List<Event> parsedEvents = (eventList as List)
              .map(
                (eventJson) =>
                    Event.fromJson(eventJson as Map<String, dynamic>),
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
  static Future<bool> saveEvents(Map<DateTime, List<Event>> events) async {
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
  static Future<bool> addEvent(DateTime date, Event event) async {
    final normalizedDate = _normalizeDate(date);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id);
      await docRef.set(event.toJson());

      // Update local cache
      final events = await loadEvents();
      events.putIfAbsent(normalizedDate, () => []);
      events[normalizedDate]!.add(event);
      await saveEvents(events);
      return true;
    } catch (e) {
      print('Error adding event to Firestore: $e');
      // Fall back to local-only save
      final events = await loadEvents();
      events.putIfAbsent(normalizedDate, () => []);
      events[normalizedDate]!.add(event);
      return await saveEvents(events);
    }
  }

  // Remove an event from storage
  static Future<bool> removeEvent(DateTime date, Event event) async {
    final normalizedDate = _normalizeDate(date);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id);
      await docRef.delete();

      final events = await loadEvents();
      events[normalizedDate]?.removeWhere((e) => e.id == event.id);
      if (events[normalizedDate]?.isEmpty ?? false) {
        events.remove(normalizedDate);
      }
      await saveEvents(events);
      return true;
    } catch (e) {
      print('Error removing event from Firestore: $e');
      // Fallback to local-only removal
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
    Event oldEvent,
    Event newEvent,
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
  static Future<List<Event>> getEventsForDate(DateTime date) async {
    final events = await loadEvents();
    final normalizedDate = _normalizeDate(date);
    return events[normalizedDate] ?? [];
  }

  /// Get events for a date range
  static Future<List<Event>> getEventsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final events = await loadEvents();
    final List<Event> rangeEvents = [];

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
