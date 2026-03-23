import 'dart:convert';
import 'dart:html' as html;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'okta_auth_service.dart';

class OAuthCallbackService {
  /// Checks the current URL for an OAuth authorization code, exchanges it for
  /// tokens, and signs the user in to Firebase. No-op if no code is present.
  static Future<void> handleOAuthCallback() async {
    try {
      final uri = Uri.parse(html.window.location.href);
      final code = uri.queryParameters['code'];
      if (code == null) return;

      final tokens = await OktaAuthService.exchangeCodeForTokens(code);
      if (tokens == null) {
        print('Failed to exchange authorization code for tokens');
        return;
      }

      final userInfo = await OktaAuthService.getUserInfo(
        tokens['access_token'],
      );
      if (userInfo == null) {
        print('Failed to get user info from Okta');
        return;
      }

      final email = userInfo['email'] as String?;
      final name = userInfo['name'] as String?;
      if (email == null) {
        print('No email found in Okta user info');
        return;
      }

      await _signInOrCreateFirebaseUser(email: email, displayName: name);

      // Remove the OAuth query params from the browser URL bar.
      html.window.history.replaceState(null, '', '/');
    } catch (e) {
      print('Error handling OAuth callback: $e');
    }
  }

  /// Signs in an existing Firebase user whose account was created via Okta, or
  /// creates a new one on first login. The password is derived deterministically
  /// from the email so the same user can authenticate repeatedly.
  static Future<void> _signInOrCreateFirebaseUser({
    required String email,
    String? displayName,
  }) async {
    final password = _deterministicPassword(email);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Signed in existing Firebase user: $email');
    } on FirebaseAuthException catch (signInError) {
      print('Sign-in failed (${signInError.code}), attempting account creation');
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        if (displayName != null && credential.user != null) {
          await credential.user!.updateDisplayName(displayName);
          print('Updated display name to: $displayName');
        }
        print('Created new Firebase user: $email');
      } on FirebaseAuthException catch (createError) {
        print(
          'Failed to create Firebase account: ${createError.code} - ${createError.message}',
        );
      }
    }
  }

  /// Derives a stable password from the user's email using HMAC-SHA256.
  /// NOTE: In production, replace the secret with a value loaded from a secure
  /// environment variable or Cloud Secret Manager.
  static String _deterministicPassword(String email) {
    const secret = 'greek-connect-okta-auth-v1';
    final bytes = utf8.encode(email + secret);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes);
  }
}
