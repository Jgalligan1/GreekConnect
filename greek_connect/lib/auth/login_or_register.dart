import 'package:flutter/material.dart';
import 'package:greek_connect/screens/login_screen.dart';

class gcLoginOrRegister extends StatefulWidget {
  const gcLoginOrRegister({super.key});

  @override
  State<gcLoginOrRegister> createState() => _gcLoginOrRegisterState();
}

class _gcLoginOrRegisterState extends State<gcLoginOrRegister> {
  @override
  Widget build(BuildContext context) {
    // Only login screen is shown - university accounts only
    return const gcLoginScreen();
  }
}
