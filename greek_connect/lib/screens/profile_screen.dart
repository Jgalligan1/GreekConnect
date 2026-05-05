import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greek_connect/models/user_profile.dart';
import 'package:greek_connect/services/user_service.dart';
import 'package:greek_connect/services/invitation_code_service.dart';
import 'package:greek_connect/models/invitation_code.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final InvitationCodeService _invitationCodeService = InvitationCodeService();
  final TextEditingController _joinCodeController = TextEditingController();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isGeneratingCode = false;
  InvitationCode? _generatedCode;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final profile = await _userService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error loading profile: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateInviteCode() async {
    if (_userProfile == null) {
      _showMessage('Profile not loaded');
      return;
    }

    if (_userProfile!.organization == null ||
        _userProfile!.organization!.isEmpty) {
      _showMessage('You must be in an organization to create invite codes');
      return;
    }

    setState(() => _isGeneratingCode = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showMessage('User not authenticated');
        return;
      }

      final code = await _invitationCodeService.generateInvitationCode(
        userId,
        _userProfile!,
        _userProfile!.organization!,
        usageLimitDays: 14,
        maxUses: 999,
      );

      if (code != null) {
        setState(() => _generatedCode = code);
        _showMessage('Invite code created successfully!');
      } else {
        _showMessage('You must be an admin to create invite codes');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingCode = false);
      }
    }
  }

  Future<void> _joinOrganizationWithCode() async {
    final code = _joinCodeController.text.trim();

    if (code.isEmpty) {
      _showMessage('Please enter an invitation code');
      return;
    }

    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('Code must be 6 digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showMessage('User not authenticated');
        return;
      }

      final success = await _invitationCodeService.useInvitationCode(
        userId,
        code,
      );

      if (success) {
        _joinCodeController.clear();
        _showMessage('Successfully joined organization!');
        await _loadUserProfile();
        setState(() => _generatedCode = null);
      } else {
        _showMessage('Invalid or expired code. Please try again.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyGeneratedCodeToClipboard() {
    if (_generatedCode != null) {
      _showMessage(
        'Code: ${_generatedCode!.code} (Copy manually or share directly)',
      );
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final hasOrganization =
        _userProfile!.organization != null &&
        _userProfile!.organization!.isNotEmpty;
    final isAdmin =
        hasOrganization &&
        _userProfile!.adminForOrganizations.contains(
          _userProfile!.organization,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            const Icon(
              Icons.account_circle,
              size: 80,
              color: Color(0xFF801C0D),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email Display
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(_userProfile!.email, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            // Display Name
            const Text(
              'Display Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userProfile!.displayName ?? 'Not set',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Organization Section
            const Text(
              'Organization(s)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            if (hasOrganization) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF801C0D)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF801C0D).withOpacity(0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _userProfile!.organization ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isAdmin)
                      const Chip(
                        label: Text('Admin'),
                        backgroundColor: Color(0xFF801C0D),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: const Text(
                  'Not joined yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Join Organization Section
            if (!hasOrganization) ...[
              const Text(
                'Join an Organization?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter an invitation code to join an organization',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _joinCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                enabled: !_isLoading,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 28,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) =>
                    _isLoading ? null : _joinOrganizationWithCode(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinOrganizationWithCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF801C0D),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Join Organization',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],

            // Admin Section - Create Invite Code
            if (hasOrganization && isAdmin) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              const Text(
                'Create Invite Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Generate an invite code to share with members who want to join your organization',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isGeneratingCode ? null : _generateInviteCode,
                icon: const Icon(Icons.add),
                label: const Text('Generate New Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF801C0D),
                  foregroundColor: Colors.white,
                ),
              ),

              // Display Generated Code
              if (_generatedCode != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Invite Code Created!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        _generatedCode!.code,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Expires in ${_generatedCode!.expiresAt.difference(DateTime.now()).inDays} days',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _copyGeneratedCodeToClipboard,
                        icon: const Icon(Icons.info),
                        label: const Text('Code Details'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '💡 Share this code with others to let them join your organization. They can only join once per account.',
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
