import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:greek_connect/widgets/text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class gcLoginScreen extends StatefulWidget {
  final Function()? onTap;
  const gcLoginScreen({super.key, this.onTap});

  @override
  State<gcLoginScreen> createState() => _gcLoginScreenState();
}

class _gcLoginScreenState extends State<gcLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void signIn() async {
    // Show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Try to sign in
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context); // Remove loading circle
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Remove loading circle

      if (mounted) displayMessage(e.code);
    }
  }

  Future<void> _launchOktaSignIn() async {
    // Replace these with the values from your Okta app configuration
    const String oktaDomain = 'sio.oktapreview.com';
    const String clientId = '0oauyr79rxi4uMBDf1d7';
    const String redirectUri =
        'http://localhost:8080/authorization-code/callback';

    final Uri authUri = Uri(
      scheme: 'https',
      host: oktaDomain,
      path: '/oauth2/default/v1/authorize',
      queryParameters: {
        'client_id': clientId,
        'response_type': 'code',
        'scope': 'openid profile email',
        'redirect_uri': redirectUri,
        'state': 'state',
        'nonce': 'nonce',
      },
    );

    try {
      if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
        displayMessage('Could not open browser for Okta sign-in.');
      }
    } catch (e) {
      displayMessage('Failed to open sign-in: $e');
    }
  }

  void displayMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              gcMyTextField(
                controller: _emailController,
                hintText: 'Email',
                obscureText: false,
              ),
              const SizedBox(height: 16),
              gcMyTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  signIn();
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _launchOktaSignIn();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Login with University'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not a member?'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      'Register now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
