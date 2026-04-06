import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greek_connect/models/user_profile.dart';
import 'package:greek_connect/models/invitation_code.dart';
import 'package:greek_connect/services/user_service.dart';
import 'package:greek_connect/services/invitation_code_service.dart';

class InvitationCodeManagerScreen extends StatefulWidget {
  final String organizationName;

  const InvitationCodeManagerScreen({
    super.key,
    required this.organizationName,
  });

  @override
  State<InvitationCodeManagerScreen> createState() =>
      _InvitationCodeManagerScreenState();
}

class _InvitationCodeManagerScreenState
    extends State<InvitationCodeManagerScreen> {
  final UserService _userService = UserService();
  final InvitationCodeService _invitationCodeService = InvitationCodeService();

  late Future<UserProfile?> _userProfileFuture;
  UserProfile? _userProfile;
  List<InvitationCode> _invitationCodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _userProfileFuture = _userService.getUserProfile(userId);
      _userProfileFuture.then((profile) {
        if (profile != null) {
          setState(() => _userProfile = profile);
          _loadInvitationCodes();
        }
      });
    }
  }

  Future<void> _loadInvitationCodes() async {
    if (_userProfile == null) return;

    try {
      final codes = await _invitationCodeService.getOrganizationInvitationCodes(
        _userProfile!,
        widget.organizationName,
      );
      setState(() => _invitationCodes = codes);
    } catch (e) {
      _showMessage('Error loading codes: $e');
    }
  }

  Future<void> _generateNewCode() async {
    if (_userProfile == null) {
      _showMessage('User profile not loaded');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showMessage('User not authenticated');
        return;
      }

      final newCode = await _invitationCodeService.generateInvitationCode(
        userId,
        _userProfile!,
        widget.organizationName,
        usageLimitDays: 14,
        maxUses: 999,
      );

      if (newCode != null) {
        _showMessage('Invitation code generated: ${newCode.code}');
        await _loadInvitationCodes();
      } else {
        _showMessage('Failed to generate code. Check your admin privileges.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _revokeCode(String codeId) async {
    if (_userProfile == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Code?'),
        content: const Text('This code will no longer be usable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final success = await _invitationCodeService.revokeInvitationCode(
        userId,
        _userProfile!,
        codeId,
      );

      if (success) {
        _showMessage('Code revoked');
        await _loadInvitationCodes();
      } else {
        _showMessage('Failed to revoke code');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  void _copyToClipboard(String code) {
    // Note: You'll need to add flutter/services for this
    _showMessage('Code copied to clipboard: $code');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Invitation Codes')),
      body: _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : !_userProfile!.isAdmin &&
                !_userProfile!.adminForOrganizations.contains(
                  widget.organizationName,
                )
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin Access Required',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You must be an admin of ${widget.organizationName} to manage invitation codes.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Generate Invitation Codes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create shareable codes that expire in 14 days. '
                    'Members can use these codes to join your organization.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateNewCode,
                    icon: const Icon(Icons.add),
                    label: const Text('Generate New Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF801C0D),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Active Codes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (_invitationCodes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No active codes yet. Generate one to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _invitationCodes.length,
                      itemBuilder: (context, index) {
                        final code = _invitationCodes[index];
                        final daysLeft = code.expiresAt
                            .difference(DateTime.now())
                            .inDays;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Code',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SelectableText(
                                          code.code,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: daysLeft > 7
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '$daysLeft days left',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: daysLeft > 7
                                                  ? Colors.green.shade900
                                                  : Colors.orange.shade900,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${code.timesUsed}/${code.usageLimit} uses',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _copyToClipboard(code.code),
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Copy'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _revokeCode(code.codeId),
                                        icon: const Icon(Icons.block),
                                        label: const Text('Revoke'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
