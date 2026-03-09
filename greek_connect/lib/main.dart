// lib/main.dart

import 'package:flutter/material.dart';
import 'package:greek_connect/auth/auth.dart';
import 'package:greek_connect/screens/dashboard_screen.dart';
import 'package:greek_connect/services/okta_auth_service.dart';
import 'screens/calendar_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:crypto/crypto.dart';

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

// Generate a consistent password for Okta-authenticated users
// This ensures the same user can sign in repeatedly
String _generateDeterministicPassword(String email) {
  const String secret =
      'greek-connect-okta-auth-v1'; // Keep this secret in production
  final bytes = utf8.encode(email + secret);
  final digest = sha256.convert(bytes);
  return base64Url.encode(digest.bytes);
}

Future<void> _handleOAuthCallback() async {
  try {
    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];

    if (code != null) {
      print('=== OAuth Callback Started ===');
      print('Authorization code received: ${code.substring(0, 10)}...');

      // Exchange code for tokens
      final tokens = await OktaAuthService.exchangeCodeForTokens(code);

      if (tokens != null) {
        print('✓ Tokens received successfully');

        // Get user info from Okta
        final userInfo = await OktaAuthService.getUserInfo(
          tokens['access_token'],
        );

        if (userInfo != null) {
          print('User info: $userInfo');
          final email = userInfo['email'] as String?;
          final name = userInfo['name'] as String?;

          if (email != null) {
            print('Attempting Firebase authentication for: $email');
            try {
              // Use deterministic password (same for each email every time)
              final String password = _generateDeterministicPassword(email);

              UserCredential? userCredential;

              try {
                // Try to sign in with existing account
                userCredential = await FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                print('✓ Signed in existing user: $email');
              } on FirebaseAuthException catch (e) {
                print(
                  'Sign-in failed (${e.code}), attempting to create account',
                );
                // Try to create account for any sign-in failure
                // (user-not-found, wrong-password, invalid-credential, etc.)
                try {
                  userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                  print('✓ Created new Firebase user: $email');

                  // Update display name
                  if (name != null && userCredential.user != null) {
                    await userCredential.user!.updateDisplayName(name);
                    print('✓ Updated display name to: $name');
                  }
                } on FirebaseAuthException catch (createError) {
                  print(
                    '✗ Failed to create account: ${createError.code} - ${createError.message}',
                  );
                }
              }

              if (userCredential != null && userCredential.user != null) {
                print(
                  '✓ Firebase authentication successful for UID: ${userCredential.user!.uid}',
                );
              } else {
                print('✗ Firebase authentication failed completely');
              }
            } catch (e) {
              print('✗ Firebase sign-in error: $e');
            }
          } else {
            print('✗ No email found in Okta user info');
          }
        } else {
          print('✗ Failed to get user info from Okta');
        }

        // Clean up URL by removing query params
        html.window.history.replaceState(null, '', '/');
        print('=== OAuth Callback Completed ===');
      } else {
        print('✗ Failed to exchange authorization code for tokens');
      }
    }
  } catch (e) {
    print('✗ Error handling OAuth callback: $e');
  }
}

class gcMyApp extends StatelessWidget {
  const gcMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Duck Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blueAccent,

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF801C0D),
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
              case 3:
                // For testing only - access profile setup
                final user = snapshot.data;
                page = ProfileSetupScreen(
                  email: user?.email ?? '',
                  displayName: user?.displayName,
                );
                break;
              default:
                page = gcDashboardScreen();
            }

            return Scaffold(
              body: page,
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor:
                    Theme.of(context).appBarTheme.backgroundColor ??
                    const Color(0xFF801C0D),
                selectedItemColor:
                    Theme.of(context).appBarTheme.foregroundColor ??
                    Colors.white,
                unselectedItemColor: Colors.white70,
                selectedIconTheme: IconThemeData(
                  color:
                      Theme.of(context).appBarTheme.foregroundColor ??
                      Colors.white,
                ),
                unselectedIconTheme: const IconThemeData(color: Colors.white70),
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
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Profile',
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
