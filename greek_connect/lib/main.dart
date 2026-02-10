// lib/main.dart

import 'package:flutter/material.dart';
import 'package:greek_connect/auth/auth.dart';
import 'package:greek_connect/screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: gcDefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();
  runApp(const gcMyApp());
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}
