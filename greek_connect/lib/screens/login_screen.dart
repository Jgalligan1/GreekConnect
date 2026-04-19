import 'package:flutter/material.dart';
import 'package:greek_connect/services/okta_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class gcLoginScreen extends StatefulWidget {
  const gcLoginScreen({super.key});

  @override
  State<gcLoginScreen> createState() => _gcLoginScreenState();
}

class _gcLoginScreenState extends State<gcLoginScreen> {
  Future<void> _launchOktaSignIn() async {
    // Generate PKCE parameters
    final pkce = OktaAuthService.generatePKCE();
    await OktaAuthService.storeCodeVerifier(pkce['code_verifier']!);

    final Uri authUri = Uri(
      scheme: 'https',
      host: OktaAuthService.oktaDomain,
      path: '/oauth2/default/v1/authorize',
      queryParameters: {
        'client_id': OktaAuthService.clientId,
        'response_type': 'code',
        'scope': 'openid profile email',
        'redirect_uri': OktaAuthService.redirectUri,
        'state': 'state',
        'nonce': 'nonce',
        'code_challenge': pkce['code_challenge']!,
        'code_challenge_method': 'S256',
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
              const Text(
                'Use Okta Verify to sign in.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _launchOktaSignIn();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Log in using Okta Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
