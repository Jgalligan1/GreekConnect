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
}
