import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OktaAuthService {
  static const String oktaDomain = 'siot.okta.com';
  static const String clientId = '0oa10gv6rr8Zr3bpD698';
  static const String redirectUri =
      'http://localhost:8080/authorization-code/callback';

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
      print('Error: No code_verifier found');
      return null;
    }

    final tokenUrl = Uri.https(oktaDomain, '/oauth2/default/v1/token');

    try {
      final response = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        await clearCodeVerifier();
        return json.decode(response.body);
      } else {
        print('Token exchange failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error exchanging code for tokens: $e');
      return null;
    }
  }

  // Get user info from Okta
  static Future<Map<String, dynamic>?> getUserInfo(String accessToken) async {
    final userInfoUrl = Uri.https(oktaDomain, '/oauth2/default/v1/userinfo');

    try {
      final response = await http.get(
        userInfoUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Get user info failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}
