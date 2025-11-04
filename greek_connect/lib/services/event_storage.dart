// lib/services/event_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class EventStorage {
  static const String _key = 'events';

  static Future<Map<String, List<Event>>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return {};
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) {
      final list = (value as List).map((e) => Event(e)).toList();
      return MapEntry(key, list);
    });
  }

  static Future<void> saveEvents(Map<String, List<Event>> events) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(events.map((key, value) {
      final list = value.map((e) => e.title).toList();
      return MapEntry(key, list);
    }));
    await prefs.setString(_key, encoded);
  }
}
