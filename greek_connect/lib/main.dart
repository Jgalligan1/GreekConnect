// lib/main.dart

import 'package:flutter/material.dart';
import 'package:greek_connect/auth/auth.dart';
import 'package:greek_connect/screens/dashboard_screen.dart';
import 'package:greek_connect/services/okta_auth_service.dart';
import 'screens/calendar_screen.dart';
import 'screens/notifications_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'dart:html' as html;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: gcDefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();

  // Check for OAuth callback on web
  await _handleOAuthCallback();

  runApp(const gcMyApp());
}

Future<void> _handleOAuthCallback() async {
  try {
    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];

    if (code != null) {
      print('Authorization code received: $code');

      // Exchange code for tokens
      final tokens = await OktaAuthService.exchangeCodeForTokens(code);

      if (tokens != null) {
        print('Tokens received successfully');

        // Get user info from Okta
        final userInfo = await OktaAuthService.getUserInfo(
          tokens['access_token'],
        );

        if (userInfo != null) {
          print('User info: $userInfo');

          // Sign in to Firebase with email from Okta
          // For now, we'll create a Firebase account or sign in anonymously
          try {
            // Try to sign in anonymously for now
            await FirebaseAuth.instance.signInAnonymously();
            print('Signed in to Firebase anonymously');
          } catch (e) {
            print('Firebase sign-in error: $e');
          }
        }

        // Clean up URL by removing query params
        html.window.history.replaceState(null, '', '/');
      }
    }
  } catch (e) {
    print('Error handling OAuth callback: $e');
  }
}

class gcMyApp extends StatelessWidget {
  const gcMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Greek Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blueAccent,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        useMaterial3: true,
      ),
      home: gcMyHomePage(),
    );
  }
}

class gcMyHomePage extends StatefulWidget {
  const gcMyHomePage({super.key});

  @override
  State<gcMyHomePage> createState() => _gcMyHomePageState();
}

class _gcMyHomePageState extends State<gcMyHomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const gcAuthPage();
            }

            Widget page;
            switch (selectedIndex) {
              case 0:
                page = gcDashboardScreen();
                break;
              case 1:
                page = gcCalendarScreen();
                break;
              case 2:
                page = gcNotificationsScreen();
                break;
              default:
                page = gcDashboardScreen();
            }

            return Scaffold(
              body: page,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today),
                    label: 'Calendar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications),
                    label: 'Notifications',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
