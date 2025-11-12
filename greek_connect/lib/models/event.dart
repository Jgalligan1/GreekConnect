// lib/models/event.dart

import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final int color; // Store as int for JSON serialization
  final String? location;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  Event({
    String? id,
    required this.title,
    this.description,
    required this.date,
    int? color,
    this.location,
    this.startTime,
    this.endTime,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       color = color ?? 0xFF2196F3; // Default blue color

  // Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'color': color,
      'location': location,
      'startTime': startTime != null
          ? '${startTime!.hour}:${startTime!.minute}'
          : null,
      'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
    };
  }

  // Create Event from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      color: json['color'] as int? ?? 0xFF2196F3,
      location: json['location'] as String?,
      startTime: json['startTime'] != null
          ? _parseTimeOfDay(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? _parseTimeOfDay(json['endTime'] as String)
          : null,
    );
  }

  // Parse TimeOfDay from string
  static TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  // Get Color object from int
  Color get colorValue => Color(color);

  // Create a copy with modified fields
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    int? color,
    String? location,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      color: color ?? this.color,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
