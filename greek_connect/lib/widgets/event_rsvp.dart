import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class EventRsvpModal extends StatefulWidget {
  final Event event;

  const EventRsvpModal({super.key, required this.event});

  @override
  State<EventRsvpModal> createState() => _EventRsvpModalState();
}

class _EventRsvpModalState extends State<EventRsvpModal> {
  bool _isSaving = false;

  Future<void> _saveRsvp(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to RSVP')),
      );
      setState(() => _isSaving = false);
      return Navigator.pop(context, false);
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

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save RSVP: $e')));
      // Close the modal even on error so the user isn't stuck behind it.
      Navigator.pop(context, false);
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
          ElevatedButton(
            onPressed: _isSaving ? null : () => _saveRsvp(context),
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
