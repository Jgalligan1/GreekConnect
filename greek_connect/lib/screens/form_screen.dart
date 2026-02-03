// lib/screens/form_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class FormScreen extends StatefulWidget {
  final DateTime selectedDate;

  const FormScreen({super.key, required this.selectedDate});

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _eventDate;

  String _eventTitle = '';
  String _eventDescription = '';
  String _eventLocation = '';

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _eventDate = widget.selectedDate;
  }

  // Helper to format time or show placeholder
  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // TITLE FIELD
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Event Title'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter an event title'
                      : null,
                  onSaved: (value) => _eventTitle = value!,
                ),

                // DESCRIPTION FIELD
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Event Description',
                  ),
                  onSaved: (value) => _eventDescription = value ?? '',
                ),
                const SizedBox(height: 20),

                // LOCATION FIELD
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a location'
                      : null,
                  onSaved: (value) => _eventLocation = value!,
                ),

                const SizedBox(height: 20),

                // START TIME PICKER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Start Time: ${_formatTime(_startTime)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _startTime = picked);
                        }
                      },
                      child: const Text("Pick Start"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // END TIME PICKER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "End Time: ${_formatTime(_endTime)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      },
                      child: const Text("Pick End"),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // SAVE BUTTON
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_startTime == null || _endTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please select BOTH start and end times.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      _formKey.currentState!.save();

                      final newEvent = Event(
                        id: UniqueKey().toString(),
                        title: _eventTitle,
                        description: _eventDescription,
                        date: _eventDate,
                        location: _eventLocation,
                        startTime: _startTime,
                        endTime: _endTime,
                        userId: FirebaseAuth.instance.currentUser?.uid,
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
      ),
    );
  }
}
