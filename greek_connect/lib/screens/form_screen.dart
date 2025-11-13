// lib/screens/form_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';
import '../services/event_storage.dart';

class FormScreen extends StatefulWidget {
  final DateTime selectedDate;

  const FormScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _eventDate;
  String _eventTitle = '';
  String _eventDescription = '';

  @override
  void initState() {
    super.initState();
    _eventDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _eventTitle = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Event Description'),
                onSaved: (value) {
                  _eventDescription = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final newEvent = Event(
                      id: UniqueKey().toString(),
                      title: _eventTitle,
                      description: _eventDescription,
                      date: _eventDate,
                    );
                    Navigator.pop(context, newEvent);
                  }
                },
                child: const Text('Save Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}