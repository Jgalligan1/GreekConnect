// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    'Welcome to the Dashboard!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 150),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'My Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'My Organizations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SettingsScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // RIGHT COLUMN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 125),
                  Padding(
                    padding: EdgeInsets.only(right: 10.0),
                    child: Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(
                      'Chi Phi is hosting a philanthropy event on Saturday at 3 PM.\nRSVP: Yes/No',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Divider(
                    thickness: 3,
                    endIndent: 50,
                    color: Colors.blueAccent,
                    height: 50,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10),
                    child: Text(
                      'From Jim: Don\'t forget about the meeting tomorrow at 5 PM in the student center.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Divider(
                    thickness: 3,
                    endIndent: 50,
                    color: Colors.blueAccent,
                    height: 50,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10),
                    child: Text(
                      'Kappa Sigma has a social event next Friday at 7 PM. Location: TBA.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Divider(
                    thickness: 3,
                    endIndent: 50,
                    color: Colors.blueAccent,
                    height: 50,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10),
                    child: Text(
                      'Delta Phi Epsilon is organizing a CH-115 study session this Thursday at 6 PM in the library. \nRSVP: Yes/No',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Divider(
                    thickness: 3,
                    endIndent: 50,
                    color: Colors.blueAccent,
                    height: 50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
