import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:greek_connect/auth/login_or_register.dart';
import 'package:greek_connect/screens/dashboard_screen.dart';

class gcAuthPage extends StatelessWidget {
  const gcAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const gcDashboardScreen();
          } else {
            return const gcLoginOrRegister();
          }
        },
      ),
    );
  }
}
