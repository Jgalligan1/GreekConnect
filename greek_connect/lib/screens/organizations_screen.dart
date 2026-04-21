import 'package:flutter/material.dart';
import 'package:greek_connect/screens/settings_screen.dart';

class gcOrganizationsScreen extends StatelessWidget {
  const gcOrganizationsScreen({super.key});

  Future<void> _openTopMenuDestination(
    BuildContext context,
    String value,
  ) async {
    if (value == 'settings') {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const gcSettingsScreen()),
      );
    }
  }

  // Temporary mock data
  final List<String> myOrganizations = const ['Chi Phi', 'FSL Office'];

  final List<String> otherOrganizations = const [
    'Alphi Phi Omega',
    'Phi Sigma Kappa',
    'Chi Psi',
    'Theta Phi Alpha',
    'Alpha Phi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) => _openTopMenuDestination(context, value),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // MY ORGANIZATIONS HEADER
            const Text(
              'My Organizations',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // MY ORGANIZATIONS LIST
            ...myOrganizations.map(
              (org) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(org, style: const TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 20),

            // OTHER ORGANIZATIONS HEADER
            const Text(
              'Other Organizations',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // OTHER ORGANIZATIONS LIST
            ...otherOrganizations.map(
              (org) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(org, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
