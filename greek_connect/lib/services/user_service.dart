import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greek_connect/models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user profile: $e');
      return false;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create new user profile
  Future<bool> createUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(profile.toMap());
      return true;
    } catch (e) {
      print('Error creating user profile: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .update(profile.toMap());
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Update last login time
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Update organization
  Future<bool> updateOrganization(String uid, String organization) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'organization': organization,
      });
      return true;
    } catch (e) {
      print('Error updating organization: $e');
      return false;
    }
  }

  // Get organizations for a user profile.
  // Supports both legacy single 'organization' and optional list 'organizations'.
  Future<List<String>> getUserOrganizations(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      final data = doc.data();
      if (data == null) return [];

      final Set<String> organizations = <String>{};

      final org = data['organization'];
      if (org is String && org.trim().isNotEmpty) {
        organizations.add(org.trim());
      }

      final orgs = data['organizations'];
      if (orgs is List) {
        for (final value in orgs) {
          if (value is String && value.trim().isNotEmpty) {
            organizations.add(value.trim());
          }
        }
      }

      return organizations.toList()..sort();
    } catch (e) {
      print('Error loading user organizations: $e');
      return [];
    }
  }

  // Load notification preferences (returns defaults for missing keys)
  Future<Map<String, bool>> getNotificationPreferences(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      final raw =
          doc.data()?['notificationPreferences'] as Map<String, dynamic>?;
      if (raw == null) return {};
      return raw.map((k, v) => MapEntry(k, v as bool));
    } catch (e) {
      print('Error loading notification preferences: $e');
      return {};
    }
  }

  // Watch notification preferences in realtime for this user
  Stream<Map<String, bool>> watchNotificationPreferences(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((doc) {
      final raw = doc.data()?['notificationPreferences'] as Map<String, dynamic>?;
      if (raw == null) return <String, bool>{};
      return raw.map((k, v) => MapEntry(k, v as bool));
    });
  }

  // Persist notification preferences (merged so other user fields are untouched)
  Future<void> saveNotificationPreferences(
    String uid,
    Map<String, bool> prefs,
  ) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).set(
        {'notificationPreferences': prefs},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error saving notification preferences: $e');
    }
  }

  // Read current admin flag for a user.
  Future<bool> getIsAdmin(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return (doc.data()?['isAdmin'] as bool?) ?? false;
    } catch (e) {
      print('Error loading admin flag: $e');
      return false;
    }
  }

  // Test helper to toggle admin mode on the user document.
  Future<bool> setIsAdmin(String uid, bool isAdmin) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).set(
        {'isAdmin': isAdmin},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      print('Error updating admin flag: $e');
      return false;
    }
  }
}
