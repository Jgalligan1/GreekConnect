import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OktaAuthService {
  static const String oktaDomain = 'siot.okta.com';
  static const String clientId = '0oa10txmvbz70TDyh698';

  // Use the root URL as redirect URI - MUST match exactly what's configured in Okta app
  // static const String redirectUri = 'http://localhost:8080/';
  // For production:
  static const String redirectUri = 'https://symposia.web.app/';

  // Generate PKCE code_verifier and code_challenge
  static Map<String, String> generatePKCE() {
    final random = Random.secure();
    final codeVerifier = base64UrlEncode(
      List<int>.generate(32, (i) => random.nextInt(256)),
    ).replaceAll('=', '');

    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');

    return {'code_verifier': codeVerifier, 'code_challenge': codeChallenge};
  }

  // Store code_verifier for later use
  static Future<void> storeCodeVerifier(String codeVerifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('okta_code_verifier', codeVerifier);
  }

  // Retrieve stored code_verifier
  static Future<String?> getCodeVerifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('okta_code_verifier');
  }

  // Clear stored code_verifier
  static Future<void> clearCodeVerifier() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('okta_code_verifier');
  }

  // Exchange authorization code for tokens
  static Future<Map<String, dynamic>?> exchangeCodeForTokens(
    String code,
  ) async {
    final codeVerifier = await getCodeVerifier();
    if (codeVerifier == null) {
      print('ERROR: No code_verifier found in storage');
      return null;
    }

    print('Attempting token exchange:');
    print('  - Code: ${code.substring(0, 20)}...');
    print('  - Code Verifier length: ${codeVerifier.length}');
    print('  - Client ID: $clientId');
    print('  - Redirect URI: $redirectUri');

    final tokenUrl = Uri.https(oktaDomain, '/oauth2/default/v1/token');
    print('  - Token URL: $tokenUrl');

    try {
      // Build the request body with proper URL encoding
      final bodyParams = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      };

      print('Request body keys: ${bodyParams.keys.join(', ')}');
      print('Request headers: Content-Type: application/x-www-form-urlencoded');

      // Manually URL-encode the body to ensure proper formatting
      final encodedBody = bodyParams.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      print('Encoded request body: $encodedBody');

      final response = await http.post(
        tokenUrl,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: encodedBody, // Send as pre-encoded string, not as Map
      );

      print('Token exchange response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await clearCodeVerifier();
        print('Successfully exchanged code for tokens');
        return json.decode(response.body);
      } else {
        print(
          'ERROR: Token exchange failed with status ${response.statusCode}',
        );
        print('ERROR Response: ${response.body}');

        // Try to parse error details
        try {
          final errorBody = json.decode(response.body);
          print('ERROR Code: ${errorBody['errorCode']}');
          print('ERROR Summary: ${errorBody['errorSummary']}');
        } catch (e) {
          print('Could not parse error response as JSON');
        }

        return null;
      }
    } catch (e) {
      print('Error exchanging code for tokens: $e');
      return null;
    }
  }

  // Get user info from Okta
  static Future<Map<String, dynamic>?> getUserInfo(String accessToken) async {
    print('Fetching user info from Okta...');
    print('  - Access token length: ${accessToken.length}');
    print('  - Token preview: ${accessToken.substring(0, 20)}...');

    final userInfoUrl = Uri.https(oktaDomain, '/oauth2/default/v1/userinfo');
    print('  - User info URL: $userInfoUrl');

    try {
      final response = await http.get(
        userInfoUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print('User info response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        print('Successfully fetched user info');
        return json.decode(response.body);
      } else {
        print('ERROR: Get user info failed with status ${response.statusCode}');
        print('ERROR Response: ${response.body}');

        // Try to parse error details
        try {
          final errorBody = json.decode(response.body);
          print('ERROR: ${errorBody['error'] ?? errorBody['errorCode']}');
        } catch (e) {
          print('Could not parse error response as JSON');
        }

        return null;
      }
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}
