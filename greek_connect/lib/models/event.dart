// lib/models/event.dart

import 'package:flutter/material.dart';

class gcEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final int color;
  final String? location;
  final String? userId;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  gcEvent({
    String? id,
    required this.title,
    this.description,
    required this.date,
    int? color,
    this.location,
    this.userId,
    this.startTime,
    this.endTime,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       color = color ?? 0xFF2196F3;

  // Convert Event → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'color': color,
      'location': location,
      'userId': userId,
      'startTime': startTime != null ? _formatTime(startTime!) : null,
      'endTime': endTime != null ? _formatTime(endTime!) : null,
    };
  }

  // Standardize time format for saving
  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Create Event ← JSON
  factory gcEvent.fromJson(Map<String, dynamic> json) {
    return gcEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      color: json['color'] as int? ?? 0xFF2196F3,
      location: json['location'] as String?,
      userId: json['userId'] as String?,
      startTime: json['startTime'] != null
          ? _parseTimeOfDay(json['startTime'])
          : null,
      endTime: json['endTime'] != null
          ? _parseTimeOfDay(json['endTime'])
          : null,
    );
  }

  // Parse "HH:MM" into TimeOfDay
  static TimeOfDay _parseTimeOfDay(String? value) {
    if (value == null) return TimeOfDay(hour: 0, minute: 0);

    try {
      final parts = value.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      print("Time parse error: $e (value: $value)");
      return TimeOfDay(hour: 0, minute: 0);
    }
  }

  Color get colorValue => Color(color);

  gcEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    int? color,
    String? location,
    String? userId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return gcEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      color: color ?? this.color,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is gcEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
