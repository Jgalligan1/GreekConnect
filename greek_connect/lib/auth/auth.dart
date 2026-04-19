import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:greek_connect/screens/login_screen.dart';
import 'package:greek_connect/screens/dashboard_screen.dart';
import 'package:greek_connect/screens/profile_setup_screen.dart';
import 'package:greek_connect/services/user_service.dart';

class gcAuthPage extends StatelessWidget {
  const gcAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print(
            'Auth state changed: hasData=${snapshot.hasData}, user=${snapshot.data?.email}',
          );

          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            print('User authenticated: ${user.email} (UID: ${user.uid})');

            // User is authenticated, check if profile is complete
            return FutureBuilder<bool>(
              future: UserService().userProfileExists(user.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  print('Checking if profile exists...');
                  return const Center(child: CircularProgressIndicator());
                }

                final profileExists =
                    profileSnapshot.hasData && profileSnapshot.data == true;
                print('Profile exists: $profileExists');

                if (profileExists) {
                  // Profile exists, update last login and show dashboard
                  print('Navigating to dashboard');
                  UserService().updateLastLogin(user.uid);
                  return const gcDashboardScreen();
                } else {
                  // Profile doesn't exist, show setup screen
                  print('Navigating to profile setup');
                  return ProfileSetupScreen(
                    email: user.email ?? '',
                    displayName: user.displayName,
                  );
                }
              },
            );
          } else {
            print('No user authenticated, showing login screen');
            return const gcLoginScreen();
          }
        },
      ),
    );
  }
}
