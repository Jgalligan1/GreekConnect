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
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((
      doc,
    ) {
      final raw =
          doc.data()?['notificationPreferences'] as Map<String, dynamic>?;
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
      await _firestore.collection(_usersCollection).doc(uid).set({
        'notificationPreferences': prefs,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving notification preferences: $e');
    }
  }

  /// Check if user is an admin of any organization.
  /// Returns true if user is in adminForOrganizations list.
  Future<bool> isUserAdminAnywhere(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      final data = doc.data();
      if (data == null) return false;

      // Check if user has any organization admin roles
      final adminOrgs = data['adminForOrganizations'] as List?;
      return adminOrgs != null && adminOrgs.isNotEmpty;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Organization Member Management Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all members in an organization.
  /// Queries users where 'organizations' array contains the organization name.
  Future<List<UserProfile>> getOrganizationMembers(
    String organizationName,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('organizations', arrayContains: organizationName)
          .orderBy('displayName')
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching organization members: $e');
      return [];
    }
  }

  /// Promote a user to admin in the specified organization.
  /// Returns false if currentUserId is not already an admin of that organization.
  Future<bool> promoteToAdmin(
    String currentUserId,
    String targetUserId,
    String organizationName,
  ) async {
    try {
      // Verify caller is admin for this organization
      final currentUserDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .get();
      final currentUserData = currentUserDoc.data();

      if (currentUserData == null) {
        print('Error: Current user not found');
        return false;
      }

      final adminForOrgs = List<String>.from(
        currentUserData['adminForOrganizations'] ?? [],
      );

      // Check if user is admin: either explicit org admin or global admin with primary org
      bool isCurrentUserAdmin = adminForOrgs.contains(organizationName);
      if (!isCurrentUserAdmin &&
          (currentUserData['isAdmin'] as bool? ?? false)) {
        final primaryOrg = currentUserData['organization'] as String?;
        isCurrentUserAdmin = primaryOrg == organizationName;
      }

      if (!isCurrentUserAdmin) {
        print('Error: Current user is not an admin of $organizationName');
        return false;
      }

      // Get target user
      final targetUserDoc = await _firestore
          .collection(_usersCollection)
          .doc(targetUserId)
          .get();
      final targetUserData = targetUserDoc.data();

      if (targetUserData == null) {
        print('Error: Target user not found');
        return false;
      }

      // Add organization to target user's adminForOrganizations
      final targetAdminForOrgs = List<String>.from(
        targetUserData['adminForOrganizations'] ?? [],
      );
      if (!targetAdminForOrgs.contains(organizationName)) {
        targetAdminForOrgs.add(organizationName);

        await _firestore.collection(_usersCollection).doc(targetUserId).set({
          'adminForOrganizations': targetAdminForOrgs,
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      print('Error promoting user to admin: $e');
      return false;
    }
  }

  /// Demote a user from admin status in the specified organization.
  /// Returns false if:
  /// - currentUserId is not an admin of that organization
  /// - Demotion would leave the organization with fewer than 2 admins
  Future<bool> demoteFromAdmin(
    String currentUserId,
    String targetUserId,
    String organizationName,
  ) async {
    try {
      // Verify caller is admin for this organization
      final currentUserDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .get();
      final currentUserData = currentUserDoc.data();

      if (currentUserData == null) {
        print('Error: Current user not found');
        return false;
      }

      final adminForOrgs = List<String>.from(
        currentUserData['adminForOrganizations'] ?? [],
      );

      // Check if user is admin: either explicit org admin or global admin with primary org
      bool isCurrentUserAdmin = adminForOrgs.contains(organizationName);
      if (!isCurrentUserAdmin &&
          (currentUserData['isAdmin'] as bool? ?? false)) {
        final primaryOrg = currentUserData['organization'] as String?;
        isCurrentUserAdmin = primaryOrg == organizationName;
      }

      if (!isCurrentUserAdmin) {
        print('Error: Current user is not an admin of $organizationName');
        return false;
      }

      // Check if target user is admin of this organization
      final targetUserDoc = await _firestore
          .collection(_usersCollection)
          .doc(targetUserId)
          .get();
      final targetUserData = targetUserDoc.data();

      if (targetUserData == null) {
        print('Error: Target user not found');
        return false;
      }

      final targetAdminForOrgs = List<String>.from(
        targetUserData['adminForOrganizations'] ?? [],
      );
      if (!targetAdminForOrgs.contains(organizationName)) {
        print('Error: Target user is not an admin of $organizationName');
        return false;
      }

      // Count current admins in the organization
      final adminSnapshot = await _firestore
          .collection(_usersCollection)
          .where('adminForOrganizations', arrayContains: organizationName)
          .get();

      final adminCount = adminSnapshot.docs.length;

      // Check 2-admin minimum
      if (adminCount <= 2) {
        print(
          'Error: Cannot demote user. Organization would have fewer than 2 admins.',
        );
        return false;
      }

      // Remove organization from target user's adminForOrganizations
      targetAdminForOrgs.remove(organizationName);
      await _firestore.collection(_usersCollection).doc(targetUserId).set({
        'adminForOrganizations': targetAdminForOrgs,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error demoting user from admin: $e');
      return false;
    }
  }

  /// Remove a user from an organization entirely.
  /// Removes them from both 'organization' and 'organizations' fields.
  /// Returns false if currentUserId is not an admin of that organization.
  Future<bool> removeUserFromOrganization(
    String currentUserId,
    String targetUserId,
    String organizationName,
  ) async {
    try {
      // Verify caller is admin for this organization
      final currentUserDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .get();
      final currentUserData = currentUserDoc.data();

      if (currentUserData == null) {
        print('Error: Current user not found');
        return false;
      }

      final adminForOrgs = List<String>.from(
        currentUserData['adminForOrganizations'] ?? [],
      );

      // Check if user is admin: either explicit org admin or global admin with primary org
      bool isCurrentUserAdmin = adminForOrgs.contains(organizationName);
      if (!isCurrentUserAdmin &&
          (currentUserData['isAdmin'] as bool? ?? false)) {
        final primaryOrg = currentUserData['organization'] as String?;
        isCurrentUserAdmin = primaryOrg == organizationName;
      }

      if (!isCurrentUserAdmin) {
        print('Error: Current user is not an admin of $organizationName');
        return false;
      }

      // Get target user
      final targetUserDoc = await _firestore
          .collection(_usersCollection)
          .doc(targetUserId)
          .get();
      final targetUserData = targetUserDoc.data();

      if (targetUserData == null) {
        print('Error: Target user not found');
        return false;
      }

      // Remove from organizations array
      final organizations = List<String>.from(
        targetUserData['organizations'] ?? [],
      );
      organizations.remove(organizationName);

      // Handle primary organization field
      final primaryOrg = targetUserData['organization'];
      String? newPrimaryOrg;

      if (primaryOrg == organizationName) {
        // If removing the primary org, set to the first remaining org (if any)
        newPrimaryOrg = organizations.isNotEmpty ? organizations.first : null;
      }

      // Update target user
      await _firestore.collection(_usersCollection).doc(targetUserId).set({
        'organizations': organizations,
        if (primaryOrg == organizationName) 'organization': newPrimaryOrg,
      }, SetOptions(merge: true));

      // Also remove from adminForOrganizations if present
      final targetAdminForOrgs = List<String>.from(
        targetUserData['adminForOrganizations'] ?? [],
      );
      if (targetAdminForOrgs.contains(organizationName)) {
        targetAdminForOrgs.remove(organizationName);
        await _firestore.collection(_usersCollection).doc(targetUserId).set({
          'adminForOrganizations': targetAdminForOrgs,
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      print('Error removing user from organization: $e');
      return false;
    }
  }
}
