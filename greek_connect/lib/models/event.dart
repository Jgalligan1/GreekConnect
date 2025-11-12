// lib/models/event.dart

import 'package:flutter/material.dart';

class Event {
  final String title;
  final String? description;
  final Color color;

  Event(this.title, {this.description, this.color = Colors.blue});

  @override
  String toString() => title;
}
