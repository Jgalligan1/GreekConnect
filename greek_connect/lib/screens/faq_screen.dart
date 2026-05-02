// lib/screens/faq_screen.dart

import 'package:flutter/material.dart';

class gcFAQScreen extends StatefulWidget {
  const gcFAQScreen({super.key});

  @override
  State<gcFAQScreen> createState() => _gcFAQScreenState();
}

class _gcFAQScreenState extends State<gcFAQScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'About Symposia',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Symposia is a comprehensive event management and social platform designed specifically for Greek life communities. '
              'Our app helps members of Greek organizations stay connected, informed, and engaged with their community.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              index: 0,
              question: 'What is Symposia?',
              answer:
                  'Symposia is a mobile application built for Greek life organizations. It provides a centralized platform for event management, '
                  'member notifications, and community engagement. The app allows members to discover, RSVP to, and manage Greek life events all in one place.',
            ),
            _buildFAQItem(
              index: 1,
              question: 'How do I join an organization?',
              answer:
                  'You can join an organization in two ways:\n\n'
                  '1. If you have an invitation code from an organization officer, use the "Join Organization" option to enter the code.\n\n'
                  '2. You can view available organizations and send a request to join through the Organizations tab.',
            ),
            _buildFAQItem(
              index: 2,
              question: 'How do I RSVP to an event?',
              answer:
                  'To RSVP to an event:\n\n'
                  '1. Navigate to the Calendar tab to see upcoming events.\n\n'
                  '2. Find the event you\'re interested in and click "RSVP".\n\n'
                  '3. Your RSVP will be recorded and you\'ll receive notifications about the event.\n\n'
                  '4. You can view all your RSVPd events on the Dashboard.',
            ),
            _buildFAQItem(
              index: 3,
              question: 'Can I cancel my RSVP?',
              answer:
                  'Yes! You can cancel your RSVP at any time. Simply navigate to your RSVPd event on the Dashboard or Calendar '
                  'and click the "Un-RSVP" button. You\'ll receive a confirmation that your RSVP has been cancelled.',
            ),
            _buildFAQItem(
              index: 4,
              question: 'How do I receive notifications?',
              answer:
                  'GreekConnect sends notifications for:\n\n'
                  '• Upcoming events you\'ve RSVPd to\n'
                  '• Important announcements from your organizations\n'
                  '• New events from organizations you\'ve joined\n\n'
                  'You can manage your notification preferences in the Settings tab.',
            ),
            _buildFAQItem(
              index: 5,
              question: 'What information is in my profile?',
              answer:
                  'Your profile includes:\n\n'
                  '• Your name and email\n'
                  '• Your photo\n'
                  '• The organizations you\'ve joined\n'
                  '• Your event history and RSVPs\n\n'
                  'You can update your profile information at any time through the Profile tab.',
            ),
            _buildFAQItem(
              index: 6,
              question: 'Is my personal information secure?',
              answer:
                  'Yes, we take security seriously. Your data is encrypted and stored securely using Firebase. '
                  'We never share your personal information with third parties without your consent. '
                  'For more details, please review our privacy policy.',
            ),
            _buildFAQItem(
              index: 7,
              question: 'How do I contact support?',
              answer:
                  'If you encounter any issues or have questions not answered here, you can:\n\n'
                  '• Contact an officer from your organization\n'
                  '• Check the Settings tab for additional support options\n'
                  '• Email us directly for urgent matters',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required int index,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedIndex == index;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF801C0D),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isExpanded ? const Color(0xFFF5F5F5) : Colors.white,
          ),
          child: ExpansionTile(
            title: Text(
              question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF801C0D),
              ),
            ),
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedIndex = expanded ? index : null;
              });
            },
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF801C0D),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
