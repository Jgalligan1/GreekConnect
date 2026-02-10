import 'package:flutter/material.dart';
import 'package:greek_connect/screens/login_screen.dart';
import 'package:greek_connect/screens/register_screen.dart';

class gcLoginOrRegister extends StatefulWidget {
  const gcLoginOrRegister({super.key});

  @override
  State<gcLoginOrRegister> createState() => _gcLoginOrRegisterState();
}

class _gcLoginOrRegisterState extends State<gcLoginOrRegister> {
  bool showLogin = true;

  void toggleScreens() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLogin) {
      return gcLoginScreen(onTap: toggleScreens);
    } else {
      return gcRegisterScreen(onTap: toggleScreens);
    }
  }
}
