import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../services/user_service.dart';

class gcEventFormModal extends StatefulWidget {
  final DateTime selectedDate;
  final gcEvent? initialEvent;

  const gcEventFormModal({
    super.key,
    required this.selectedDate,
    this.initialEvent,
  });

  @override
  State<gcEventFormModal> createState() => _gcEventFormModalState();
}

class _gcEventFormModalState extends State<gcEventFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  String _title = '';
  String _description = '';
  String? _selectedOrganization;
  List<String> _availableOrganizations = [];
  bool _loadingOrganizations = true;
  String _location = '';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEvent;
    if (initial != null) {
      _title = initial.title;
      _description = initial.description ?? '';
      _selectedOrganization = initial.organization;
      _location = initial.location ?? '';
      _startTime = initial.startTime;
      _endTime = initial.endTime;
    }
    _loadUserOrganizations();
  }

  Future<void> _loadUserOrganizations() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _availableOrganizations = [];
          _loadingOrganizations = false;
        });
      }
      return;
    }

    final organizations = await _userService.getUserOrganizations(uid);
    if (!mounted) return;

    setState(() {
      _availableOrganizations = organizations;
      if (_selectedOrganization == null ||
          !_availableOrganizations.contains(_selectedOrganization)) {
        _selectedOrganization = _availableOrganizations.isNotEmpty
            ? _availableOrganizations.first
            : null;
      }
      _loadingOrganizations = false;
    });
  }

  bool _isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null &&
        FirebaseAuth.instance.currentUser!.uid.isNotEmpty;
  }

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF51539C),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(isPhone ? 16 : 12),
                      ),
                    ),
                    child: Text(
                      widget.initialEvent == null
                          ? 'Create Event'
                          : 'Edit Event',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ----- No Organizations Error -----
                  if (_availableOrganizations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'You do not belong to any organizations. Only members of organizations can create events. Please join an organization first.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  // ----- Title -----
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 18),
                      initialValue: _title,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF51539C)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF51539C),
                            width: 2,
                          ),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF51539C)),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF51539C),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
                      initialValue: _description,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF51539C)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF51539C),
                            width: 2,
                          ),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF51539C)),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF51539C),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
                      initialValue: _location,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF51539C)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF51539C),
                            width: 2,
                          ),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF51539C)),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF51539C),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
                            initialTime: _startTime ?? TimeOfDay.now(),
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
                            initialTime: _endTime ?? TimeOfDay.now(),
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
                        onPressed: _availableOrganizations.isEmpty || !_isUserAuthenticated()
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  final existing = widget.initialEvent;
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  
                                  // Ensure user is authenticated before creating event
                                  if (currentUser == null || currentUser.uid.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('You must be signed in to create an event'),
                                      ),
                                    );
                                    return;
                                  }

                                  print('DEBUG: Form save - current user uid=${currentUser.uid}');
                                  print('DEBUG: Form save - current user email=${currentUser.email}');

                                  final newEvent = gcEvent(
                                    id: existing?.id ?? UniqueKey().toString(),
                                    title: _title,
                                    description: _description,
                                    organization: _selectedOrganization,
                                    location: _location,
                                    startTime: _startTime,
                                    endTime: _endTime,
                                    date: widget.selectedDate,
                                    userId: existing?.userId ?? currentUser.uid,
                                    color: existing?.color,
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
