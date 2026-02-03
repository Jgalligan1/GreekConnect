import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class EventFormModal extends StatefulWidget {
  final DateTime selectedDate;

  const EventFormModal({super.key, required this.selectedDate});

  @override
  State<EventFormModal> createState() => _EventFormModalState();
}

class _EventFormModalState extends State<EventFormModal> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  String _location = '';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isPhone = screenWidth < 600;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: isPhone ? 0.95 : 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isPhone ? 16 : 12),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: media.viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ----- Title -----
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 12,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _title = v!,
                    ),
                  ),

                  // ----- Description -----
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 18),
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 12,
                        ),
                      ),
                      onSaved: (v) => _description = v ?? '',
                    ),
                  ),

                  // ----- Location -----
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 12,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _location = v!,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ----- Start Time -----
                  Row(
                    children: [
                      const Text(
                        "Start Time: ",
                        style: TextStyle(fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _startTime = picked);
                          }
                        },
                        child: Text(
                          _startTime == null
                              ? "Select"
                              : _startTime!.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  // ----- End Time -----
                  Row(
                    children: [
                      const Text("End Time: ", style: TextStyle(fontSize: 16)),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _endTime = picked);
                          }
                        },
                        child: Text(
                          _endTime == null
                              ? "Select"
                              : _endTime!.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ----- Buttons -----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final newEvent = Event(
                              id: UniqueKey().toString(),
                              title: _title,
                              description: _description,
                              location: _location,
                              startTime: _startTime,
                              endTime: _endTime,
                              date: widget.selectedDate,
                              userId: FirebaseAuth.instance.currentUser?.uid,
                            );
                            Navigator.pop(context, newEvent);
                          }
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
