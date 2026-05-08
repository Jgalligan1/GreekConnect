import 'package:flutter/material.dart';
import 'package:greek_connect/services/okta_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:greek_connect/services/web_navigation.dart';
import 'faq_screen.dart';

class gcLoginScreen extends StatefulWidget {
  const gcLoginScreen({super.key});

  @override
  State<gcLoginScreen> createState() => _gcLoginScreenState();
}

class _gcLoginScreenState extends State<gcLoginScreen> {
  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String body,
    Color accentColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: accentColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
      final navigated = await navigateToUrl(authUri.toString());
      if (!navigated) {
        if (!await launchUrl(
          authUri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_self',
        )) {
          displayMessage('Could not open browser for Okta sign-in.');
        }
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
    const Color accentColor = Color(0xFF7A1E2C);
    const Color accentSoft = Color(0xFFF7E9EC);
    const Color accentMuted = Color(0xFFF1D6DB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const gcFAQScreen()),
              );
            },
            tooltip: 'FAQ',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accentSoft, Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: accentMuted,
                                      backgroundImage: const AssetImage(
                                        'assets/images/Symposia.png',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Welcome to Symposia',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Stay in the loop with chapter, event, and faculty updates in one place.',
                                            style: TextStyle(
                                              fontSize: 15,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildFeatureRow(
                                  Icons.event_available,
                                  'Events and announcements',
                                  'Get reminders and RSVP to upcoming chapter events.',
                                  accentColor,
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureRow(
                                  Icons.group,
                                  'Member connections',
                                  'Keep schedules updated and stay connected.',
                                  accentColor,
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureRow(
                                  Icons.verified_user,
                                  'Secure access',
                                  'Sign in with Okta Verify to keep your account protected.',
                                  accentColor,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _launchOktaSignIn,
                                    icon: const Icon(Icons.lock_open),
                                    label: const Text(
                                      'Continue with Okta Verify',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const gcFAQScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.help_outline),
                                    label: const Text(
                                      'Questions? Read the FAQ',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
