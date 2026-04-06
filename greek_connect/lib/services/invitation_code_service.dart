import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greek_connect/models/invitation_code.dart';
import 'package:greek_connect/models/user_profile.dart';

class InvitationCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _invitationCodesCollection = 'invitationCodes';
  static const String _usersCollection = 'users';

  // Generate a unique 6-digit numeric code
  Future<String> _generateUniqueCode() async {
    String code;
    bool exists = true;

    do {
      code = (Random().nextInt(900000) + 100000).toString();
      final snapshot = await _firestore
          .collection(_invitationCodesCollection)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    return code;
  }

  // Generate invitation code (Admin only)
  Future<InvitationCode?> generateInvitationCode(
    String userId,
    UserProfile userProfile,
    String organizationName, {
    int usageLimitDays = 14,
    int maxUses = 999,
  }) async {
    try {
      // Check if user is admin
      if (!userProfile.isAdmin &&
          !userProfile.adminForOrganizations.contains(organizationName)) {
        print(
          'Error: User does not have admin privileges for $organizationName',
        );
        return null;
      }

      final code = await _generateUniqueCode();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: usageLimitDays));

      final invitationCode = InvitationCode(
        codeId: _firestore.collection(_invitationCodesCollection).doc().id,
        code: code,
        organizationName: organizationName,
        createdBy: userId,
        createdAt: now,
        expiresAt: expiresAt,
        usageLimit: maxUses,
        timesUsed: 0,
        isActive: true,
      );

      await _firestore
          .collection(_invitationCodesCollection)
          .doc(invitationCode.codeId)
          .set(invitationCode.toMap());

      return invitationCode;
    } catch (e) {
      print('Error generating invitation code: $e');
      return null;
    }
  }

  // Validate invitation code (check if it exists and is valid)
  Future<InvitationCode?> validateInvitationCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection(_invitationCodesCollection)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('Error: Invalid invitation code');
        return null;
      }

      final doc = snapshot.docs.first;
      final invitationCode = InvitationCode.fromMap(doc.id, doc.data());

      if (!invitationCode.isValid) {
        print('Error: Invitation code is expired or no longer valid');
        return null;
      }

      return invitationCode;
    } catch (e) {
      print('Error validating invitation code: $e');
      return null;
    }
  }

  // Use invitation code to join organization
  Future<bool> useInvitationCode(String userId, String code) async {
    try {
      final invitationCode = await validateInvitationCode(code);
      if (invitationCode == null) {
        print('Error: Invalid or expired code');
        return false;
      }

      // Update user's organization
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        print('Error: User not found');
        return false;
      }

      // Add organization to user's organizations list (or create single org field)
      final userData = userDoc.data() as Map<String, dynamic>;
      List<String> organizations = List<String>.from(
        userData['organizations'] ?? [],
      );
      final singleOrg = userData['organization'];

      if (singleOrg != null && singleOrg.isNotEmpty) {
        if (!organizations.contains(singleOrg)) {
          organizations.add(singleOrg);
        }
      }

      if (!organizations.contains(invitationCode.organizationName)) {
        organizations.add(invitationCode.organizationName);
      }

      await _firestore.collection(_usersCollection).doc(userId).update({
        'organizations': organizations,
        'organization': invitationCode.organizationName, // Update primary org
      });

      // Increment usage count
      await _firestore
          .collection(_invitationCodesCollection)
          .doc(invitationCode.codeId)
          .update({'timesUsed': invitationCode.timesUsed + 1});

      return true;
    } catch (e) {
      print('Error using invitation code: $e');
      return false;
    }
  }

  // Revoke/disable invitation code (Admin only)
  Future<bool> revokeInvitationCode(
    String userId,
    UserProfile userProfile,
    String codeId,
  ) async {
    try {
      final codeDoc = await _firestore
          .collection(_invitationCodesCollection)
          .doc(codeId)
          .get();

      if (!codeDoc.exists) {
        print('Error: Code not found');
        return false;
      }

      final code = InvitationCode.fromMap(codeId, codeDoc.data()!);

      // Check if user is admin for this organization
      if (!userProfile.isAdmin &&
          !userProfile.adminForOrganizations.contains(code.organizationName)) {
        print(
          'Error: User does not have admin privileges for ${code.organizationName}',
        );
        return false;
      }

      await _firestore
          .collection(_invitationCodesCollection)
          .doc(codeId)
          .update({'isActive': false});

      return true;
    } catch (e) {
      print('Error revoking invitation code: $e');
      return false;
    }
  }

  // Get active invitation codes for an organization (Admin only)
  Future<List<InvitationCode>> getOrganizationInvitationCodes(
    UserProfile userProfile,
    String organizationName,
  ) async {
    try {
      // Check if user is admin for this organization
      if (!userProfile.isAdmin &&
          !userProfile.adminForOrganizations.contains(organizationName)) {
        print(
          'Error: User does not have admin privileges for $organizationName',
        );
        return [];
      }

      final snapshot = await _firestore
          .collection(_invitationCodesCollection)
          .where('organizationName', isEqualTo: organizationName)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvitationCode.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching invitation codes: $e');
      return [];
    }
  }

  // Delete expired codes (cloud function alternative - can be run manually or scheduled)
  Future<int> deleteExpiredCodes() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_invitationCodesCollection)
          .where('expiresAt', isLessThan: now.toIso8601String())
          .get();

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      print('Deleted $deletedCount expired invitation codes');
      return deletedCount;
    } catch (e) {
      print('Error deleting expired codes: $e');
      return 0;
    }
  }
}
