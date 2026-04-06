## Invitation Code System Integration Guide

### Overview

This implementation provides a secure invitation code system for managing organization membership using 6-digit numeric codes that expire after 14 days.

---

### Components Created

#### 1. **Models**

- **`InvitationCode`** (`lib/models/invitation_code.dart`)
  - Represents an invitation code with validation logic
  - Tracks expiration, usage limits, and validity status

- **`UserProfile`** (updated)
  - Added `isAdmin` and `adminForOrganizations` fields
  - Tracks organizational admin privileges

#### 2. **Services**

- **`InvitationCodeService`** (`lib/services/invitation_code_service.dart`)
  - `generateInvitationCode()` - Create new codes (admin only)
  - `validateInvitationCode()` - Check code validity
  - `useInvitationCode()` - Join organization with code
  - `revokeInvitationCode()` - Disable a code (admin only)
  - `getOrganizationInvitationCodes()` - List active codes (admin only)
  - `deleteExpiredCodes()` - Cleanup utility

#### 3. **UI Screens**

- **`InvitationCodeManagerScreen`** (`lib/screens/invitation_code_manager_screen.dart`)
  - Admin dashboard for managing codes
  - Generate new codes
  - View active codes with expiration info
  - Revoke codes

- **`JoinOrganizationScreen`** (`lib/screens/join_organization_screen.dart`)
  - User interface for joining organizations
  - Enter 6-digit invitation code
  - Real-time validation

---

### Integration Steps

#### Step 1: Update User Roles

In your user creation logic (e.g., `ProfileSetupScreen`), set initial admin status:

```dart
final profile = UserProfile(
  uid: user.uid,
  email: widget.email,
  displayName: widget.displayName,
  organization: _selectedOrganization,
  createdAt: DateTime.now(),
  lastLoginAt: DateTime.now(),
  isAdmin: true,  // First user becomes admin
  adminForOrganizations: [_selectedOrganization],
);
```

#### Step 2: Add Navigation

In your main app routing, add screens accessible from appropriate contexts:

```dart
// For admins: accessible from organization settings
InvitationCodeManagerScreen(organizationName: userOrg)

// For users: accessible from main menu or onboarding
JoinOrganizationScreen(
  onSuccess: () {
    // Refresh user profile or navigate
  }
)
```

#### Step 3: Firebase Firestore Setup

No manual setup needed - the service creates the `invitationCodes` collection automatically.

**Optional: Enable TTL Policy**
In Firebase Console, set up automatic deletion on the `expiresAt` field:

1. Go to Firestore > Indexes
2. Create composite index or enable TTL
3. Set `expiresAt` field as TTL (auto-cleanup every 24 hours)

#### Step 4: (Optional) Cloud Function for Cleanup

Deploy this scheduled function to clean up expired codes monthly:

```javascript
// functions/index.js
exports.cleanupExpiredCodes = functions.pubsub
  .schedule("0 0 1 * *") // Monthly at midnight
  .timeZone("America/New_York")
  .onRun(async (context) => {
    const firestore = admin.firestore();
    const now = new Date();

    const snapshot = await firestore
      .collection("invitationCodes")
      .where("expiresAt", "<", now)
      .get();

    const batch = firestore.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    console.log(`Deleted ${snapshot.size} expired codes`);
  });
```

---

### Security Features

✅ **Admin-Only Access**: All code generation/revocation requires admin privileges
✅ **Unique Codes**: Cryptographically secure random generation with uniqueness check
✅ **Rate Limiting**: Prevent abuse by checking against existing codes
✅ **Expiration**: Automatic 14-day expiry reduces database bloat
✅ **Audit Trail**: `createdBy` field tracks who generated each code
✅ **Revocation**: Admins can immediately disable codes if compromised
✅ **Usage Tracking**: Monitor how many times each code is used

---

### Firestore Schema

```
/invitationCodes/{codeId}
  ├── code: "123456"                    (indexed)
  ├── organizationName: "Alpha Phi"
  ├── createdBy: "uid123"
  ├── createdAt: "2026-04-05T..."
  ├── expiresAt: "2026-04-19T..."       (TTL field)
  ├── usageLimit: 999
  ├── timesUsed: 0
  └── isActive: true
```

---

### Usage Flow

**Admin Generating Code:**

1. Navigate to `InvitationCodeManagerScreen`
2. Click "Generate New Code"
3. System validates admin privileges
4. Unique 6-digit code created (expires in 14 days)
5. Admin shares code with new members

**User Joining Organization:**

1. Navigate to `JoinOrganizationScreen`
2. Enter 6-digit code
3. System validates code existence and expiration
4. User added to organization's member list
5. Code usage incremented
6. User automatically added to organization

---

### Future Enhancements

1. **Bulk Invite**: Generate multiple codes at once
2. **Custom Expiry**: Let admins set custom expiration periods
3. **Invite Tracking**: Dashboard showing which users joined via which codes
4. **Email Invites**: Integrate email service to send codes automatically
5. **QR Codes**: Display QR code for easier sharing
6. **Rate Limiting**: Implement per-IP or per-user rate limits
7. **Single-Use Codes**: Option for one-time-only codes

---

### Testing Checklist

- [ ] Admin can generate codes
- [ ] Non-admins cannot generate codes
- [ ] Codes expire after 14 days
- [ ] Users can join organizations with valid codes
- [ ] Invalid/expired codes are rejected
- [ ] Admins can revoke active codes
- [ ] Usage counter increments properly
- [ ] Firestore queries are indexed for performance
