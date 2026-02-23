import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class EventRsvpModal extends StatefulWidget {
  final gcEvent event;

  const EventRsvpModal({super.key, required this.event});

  @override
  State<EventRsvpModal> createState() => _EventRsvpModalState();
}

class _EventRsvpModalState extends State<EventRsvpModal> {
  bool _isSaving = false;
  bool? _alreadyRsvpd;

  @override
  void initState() {
    super.initState();
    _checkRsvpStatus();
  }

  Future<void> _checkRsvpStatus() async {
    // Default to not RSVPd while loading
    setState(() => _alreadyRsvpd = null);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not signed in: treat as not RSVPd (button will prompt sign-in on save)
      setState(() => _alreadyRsvpd = false);
      return;
    }

    try {
      final docId = '${widget.event.id}_${user.uid}';
      final docRef = FirebaseFirestore.instance.collection('rsvps').doc(docId);
      final snapshot = await docRef.get();
      if (!mounted) return;
      setState(() => _alreadyRsvpd = snapshot.exists);
    } catch (e) {
      if (!mounted) return;
      // On error, default to not RSVPd so user can try
      setState(() => _alreadyRsvpd = false);
    }
  }

  Future<void> _saveRsvp() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // Capture states synchronously to avoid using BuildContext across async gaps.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be signed in to RSVP')),
      );
      setState(() => _isSaving = false);
      return navigator.pop(false);
    }

    try {
      final docId = '${widget.event.id}_${user.uid}';
      final docRef = FirebaseFirestore.instance.collection('rsvps').doc(docId);
      await docRef.set({
        'eventId': widget.event.id,
        'userId': user.uid,
        'title': widget.event.title,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save RSVP: $e')),
      );
      if (mounted) navigator.pop(false);
    }
  }

  Future<void> _cancelRsvp() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // Capture states synchronously to avoid using BuildContext across async gaps.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be signed in')),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      final docId = '${widget.event.id}_${user.uid}';
      final docRef = FirebaseFirestore.instance.collection('rsvps').doc(docId);
      await docRef.delete();

      if (!mounted) return;
      setState(() => _alreadyRsvpd = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('RSVP cancelled')),
      );
      setState(() => _isSaving = false);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to cancel RSVP: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isPhone = screenWidth < 600;

    if (isPhone) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildContent(context, scrollController),
          );
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: _buildContent(context, null),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController? scrollController,
  ) {
    final media = MediaQuery.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: media.viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'RSVP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.event.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (widget.event.description != null &&
              widget.event.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(widget.event.description!),
            ),
          if (widget.event.location != null &&
              widget.event.location!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Location: ${widget.event.location}'),
            ),
          if (widget.event.startTime != null || widget.event.endTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_formatTimeRange(context)),
            ),
          const SizedBox(height: 20),
          if (_alreadyRsvpd == null)
            const Center(child: CircularProgressIndicator())
          else if (_alreadyRsvpd == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "You have already RSVP'd to this event",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: _isSaving ? null : () => _cancelRsvp(),
                  child: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Un-RSVP', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveRsvp(),
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('RSVP'),
            ),
        ],
      ),
    );
  }

  String _formatTimeRange(BuildContext context) {
    final event = widget.event;
    if (event.startTime != null && event.endTime != null) {
      return 'Time: ${event.startTime!.format(context)} - ${event.endTime!.format(context)}';
    }
    if (event.startTime != null) {
      return 'Time: Starts at ${event.startTime!.format(context)}';
    }
    if (event.endTime != null) {
      return 'Time: Ends at ${event.endTime!.format(context)}';
    }
    return '';
  }
}
