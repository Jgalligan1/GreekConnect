import 'package:flutter/material.dart';

class OrganizationsScreen extends StatelessWidget {
  const OrganizationsScreen({super.key});

  // Temporary mock data
  final List<String> myOrganizations = const [
    'Chi Phi',
    'FSL Office',
  ];

  final List<String> otherOrganizations = const [
    'OTHER ORGANIZATIONS',
    'OTHER ORGANIZATIONS',
    'OTHER ORGANIZATIONS',
    'OTHER ORGANIZATIONS',
    'OTHER ORGANIZATIONS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // MY ORGANIZATIONS HEADER
            const Text(
              'My Organizations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // MY ORGANIZATIONS LIST
            ...myOrganizations.map(
              (org) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  org,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 20),

            // OTHER ORGANIZATIONS HEADER
            const Text(
              'Other Organizations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // OTHER ORGANIZATIONS LIST
            ...otherOrganizations.map(
              (org) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  org,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
