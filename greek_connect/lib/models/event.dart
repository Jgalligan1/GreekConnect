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
      startTime: _parseTimeOfDay(json['startTime']),
      endTime: _parseTimeOfDay(json['endTime']),
    );
  }

  // Parse supported time formats into TimeOfDay.
  static TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    try {
      // 24h formats: HH:MM or HH:MM:SS
      final parts = raw.split(':');
      if (parts.length >= 2 &&
          !raw.toUpperCase().contains('AM') &&
          !raw.toUpperCase().contains('PM')) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // 12h format: h:mm AM/PM
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$',
      ).firstMatch(raw);
      if (match != null) {
        var hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final meridiem = match.group(3)!.toUpperCase();

        if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
          return null;
        }

        if (meridiem == 'AM') {
          hour = hour == 12 ? 0 : hour;
        } else {
          hour = hour == 12 ? 12 : hour + 12;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Time parse error: $e (value: $raw)');
    }

    print('Unsupported time format: $raw');
    return null;
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
