class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? organization;
  final List<String> organizations;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isAdmin;
  final List<String> adminForOrganizations;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.organization,
    this.organizations = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isAdmin = false,
    this.adminForOrganizations = const [],
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'organization': organization,
      'organizations': organizations,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isAdmin': isAdmin,
      'adminForOrganizations': adminForOrganizations,
    };
  }

  // Create from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      organization: map['organization'],
      organizations: List<String>.from(map['organizations'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
      isAdmin: map['isAdmin'] ?? false,
      adminForOrganizations: List<String>.from(
        map['adminForOrganizations'] ?? [],
      ),
    );
  }

  // Copy with method for updates
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? organization,
    List<String>? organizations,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isAdmin,
    List<String>? adminForOrganizations,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      organization: organization ?? this.organization,
      organizations: organizations ?? this.organizations,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isAdmin: isAdmin ?? this.isAdmin,
      adminForOrganizations:
          adminForOrganizations ?? this.adminForOrganizations,
    );
  }
}
