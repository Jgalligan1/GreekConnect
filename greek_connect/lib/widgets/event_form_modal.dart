import 'package:flutter/material.dart';
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
    return AlertDialog(
      title: const Text("Add Event"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _title = v!,
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (v) => _description = v ?? '',
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _location = v!,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Text("Start Time: "),
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
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  const Text("End Time: "),
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
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
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
              );

              Navigator.pop(context, newEvent);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
