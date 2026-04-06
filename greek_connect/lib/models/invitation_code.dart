class InvitationCode {
  final String codeId;
  final String code;
  final String organizationName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int usageLimit;
  final int timesUsed;
  final bool isActive;

  InvitationCode({
    required this.codeId,
    required this.code,
    required this.organizationName,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.usageLimit = 999, // Unlimited by default
    this.timesUsed = 0,
    this.isActive = true,
  });

  // Check if code is still valid
  bool get isValid {
    final now = DateTime.now();
    final isNotExpired = expiresAt.isAfter(now);
    final hasUsesAvailable = timesUsed < usageLimit;
    return isActive && isNotExpired && hasUsesAvailable;
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'organizationName': organizationName,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'usageLimit': usageLimit,
      'timesUsed': timesUsed,
      'isActive': isActive,
    };
  }

  // Create from Firestore document
  factory InvitationCode.fromMap(String codeId, Map<String, dynamic> map) {
    return InvitationCode(
      codeId: codeId,
      code: map['code'] ?? '',
      organizationName: map['organizationName'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      usageLimit: map['usageLimit'] ?? 999,
      timesUsed: map['timesUsed'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  // Copy with method for updates
  InvitationCode copyWith({
    String? code,
    String? organizationName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? usageLimit,
    int? timesUsed,
    bool? isActive,
  }) {
    return InvitationCode(
      codeId: codeId,
      code: code ?? this.code,
      organizationName: organizationName ?? this.organizationName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usageLimit: usageLimit ?? this.usageLimit,
      timesUsed: timesUsed ?? this.timesUsed,
      isActive: isActive ?? this.isActive,
    );
  }
}
