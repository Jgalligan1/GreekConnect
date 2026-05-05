import 'dart:convert';
import 'dart:html' as html;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'okta_auth_service.dart';
import 'user_service.dart';
import '../models/user_profile.dart';

class OAuthCallbackService {
  static bool _hasProcessedCallback = false;

  /// Checks the current URL for an OAuth authorization code, exchanges it for
  /// tokens, and signs the user in to Firebase. Handles both initial load and
  /// URL changes.
  static Future<void> handleOAuthCallback() async {
    print('=== handleOAuthCallback called ===');
    // Try to process the callback immediately
    await _processCallback();

    // Also listen for URL changes (in case the code appears later)
    html.window.onPopState.listen((event) {
      print('URL changed, checking for OAuth code...');
      _processCallback();
    });
  }

  static Future<void> _processCallback() async {
    // Prevent processing the callback multiple times
    if (_hasProcessedCallback) {
      print('Callback already processed, skipping');
      return;
    }

    try {
      // Get the full current URL with all details
      final currentUrl = html.window.location.href;
      final currentPathname = html.window.location.pathname ?? '';
      final currentSearch = html.window.location.search ?? '';

      print('=== OAuth Callback Debug Info ===');
      print('Full URL: $currentUrl');
      print('Pathname: $currentPathname');
      print('Search: $currentSearch');

      // Parse the URL to get query parameters
      final uri = Uri.parse(currentUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      print('Parsed query parameters:');
      print('  code: ${code != null ? '***present***' : 'null'}');
      print('  state: $state');
      print('  error: $error');
      print('  error_description: $errorDescription');
      print('  all params: ${uri.queryParameters}');

      // Check if there was an error from Okta
      if (error != null) {
        print('ERROR: Okta returned an error: $error');
        print('ERROR Description: $errorDescription');
        return;
      }

      if (code == null) {
        print(
          'No authorization code found in URL - this is normal if not in OAuth callback',
        );
        return;
      }

      // Mark that we're processing the callback
      _hasProcessedCallback = true;

      print('Exchanging authorization code for tokens...');
      final tokens = await OktaAuthService.exchangeCodeForTokens(code);
      if (tokens == null) {
        print('ERROR: Failed to exchange authorization code for tokens');
        _hasProcessedCallback = false;
        return;
      }
      print('Successfully exchanged code for tokens');

      print('Fetching user info from Okta...');
      final userInfo = await OktaAuthService.getUserInfo(
        tokens['access_token'],
      );
      if (userInfo == null) {
        print('ERROR: Failed to get user info from Okta');
        _hasProcessedCallback = false;
        return;
      }
      print('Successfully fetched user info: ${userInfo['email']}');

      final email = userInfo['email'] as String?;
      final name = userInfo['name'] as String?;
      if (email == null) {
        print('ERROR: No email found in Okta user info');
        _hasProcessedCallback = false;
        return;
      }

      try {
        print('Starting Firebase authentication for $email...');
        await _signInOrCreateFirebaseUser(email: email, displayName: name);
        print('SUCCESS: Signed in/created user: $email');
      } catch (e) {
        print('ERROR: Failed to sign in or create Firebase user: $e');
        _hasProcessedCallback = false;
        // Don't clear the URL on failure - keep it so the user can retry
        return;
      }

      // Remove the OAuth query params from the browser URL bar.
      // Only do this after successful user creation/sign-in
      html.window.history.replaceState(null, '', '/');
      print('OAuth callback completed successfully - redirecting to app');
    } catch (e) {
      print('ERROR: Unexpected error in OAuth callback handler: $e');
      _hasProcessedCallback = false;
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
      // Refresh the ID token to ensure proper state propagation
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      print('Refreshed ID token for existing user');
    } on FirebaseAuthException catch (signInError) {
      print(
        'Sign-in failed (${signInError.code}), attempting account creation',
      );
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        if (credential.user == null) {
          throw Exception('Failed to get user credential after creation');
        }

        final user = credential.user!;
        print('Created new Firebase user: $email (UID: ${user.uid})');

        if (displayName != null) {
          await user.updateDisplayName(displayName);
          print('Updated display name to: $displayName');
        }

        // For new users, refresh the ID token to ensure auth state is properly established
        await user.getIdToken(true);
        print('Refreshed ID token for new user');

        // Auto-create Firestore profile for first-time users (no organization selection needed)
        try {
          final profile = UserProfile(
            uid: user.uid,
            email: email,
            displayName: displayName,
            organization: null,
            organizations: const [],
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            isAdmin: false,
            adminForOrganizations: const [],
          );

          final userService = UserService();
          final profileCreated = await userService.createUserProfile(profile);

          if (profileCreated) {
            print('Auto-created Firestore profile for: $email');
          } else {
            print(
              'Warning: Failed to auto-create Firestore profile for: $email',
            );
            // Continue anyway - profile can be created later
          }
        } catch (profileError) {
          print('Error auto-creating Firestore profile: $profileError');
          // Continue anyway - profile can be created later
        }

        // Wait a brief moment to ensure auth state streams have emitted
        await Future.delayed(const Duration(milliseconds: 500));
      } on FirebaseAuthException catch (createError) {
        print(
          'Failed to create Firebase account: ${createError.code} - ${createError.message}',
        );
        // Provide more detailed error information
        String errorMessage = createError.message ?? 'Unknown error';
        if (createError.code == 'email-already-in-use') {
          errorMessage =
              'This email is already registered. Please sign in instead.';
        } else if (createError.code == 'invalid-email') {
          errorMessage = 'Invalid email address provided.';
        } else if (createError.code == 'weak-password') {
          errorMessage = 'Unable to complete registration. Please try again.';
        } else if (createError.code == 'operation-not-allowed') {
          errorMessage =
              'Registration is currently disabled. Please contact support.';
        }
        throw Exception('Failed to create user account: $errorMessage');
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
