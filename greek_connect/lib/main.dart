// lib/main.dart

import 'package:flutter/material.dart';
import 'package:greek_connect/auth/auth.dart';
import 'package:greek_connect/screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/organization_settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/oauth_callback_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: gcDefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();
  await OAuthCallbackService.handleOAuthCallback();

  runApp(const gcMyApp());
}

class gcMyApp extends StatelessWidget {
  const gcMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Symposia',
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

  Future<void> _openTopMenuDestination(String value) async {
    if (value == 'organization_settings') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const OrganizationSettingsScreen(),
        ),
      );
      return;
    }

    if (value == 'settings') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const gcSettingsScreen()));
    }
  }

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
                page = const ProfileScreen();
                break;
              default:
                page = gcDashboardScreen();
            }

            return Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: page),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.white,
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          child: PopupMenuButton<String>(
                            tooltip: 'Menu',
                            icon: const Icon(Icons.menu),
                            onSelected: _openTopMenuDestination,
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: 'organization_settings',
                                child: Text('Organization Settings'),
                              ),
                              PopupMenuItem<String>(
                                value: 'settings',
                                child: Text('Settings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
