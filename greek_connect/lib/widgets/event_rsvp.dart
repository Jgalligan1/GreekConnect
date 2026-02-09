import 'package:flutter/material.dart';
import '../models/event.dart';

class EventRsvpModal extends StatelessWidget {
  final Event event;

  const EventRsvpModal({super.key, required this.event});

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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: _buildContent(context, scrollController),
          );
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 520,
        ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Text(
              'RSVP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (event.description != null && event.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(event.description!),
            ),
          if (event.location != null && event.location!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Location: ${event.location}'),
            ),
          if (event.startTime != null || event.endTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_formatTimeRange(context)),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RSVP'),
          ),
        ],
      ),
    );
  }

  String _formatTimeRange(BuildContext context) {
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
