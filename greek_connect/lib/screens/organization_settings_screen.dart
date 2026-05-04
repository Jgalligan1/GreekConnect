import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greek_connect/models/user_profile.dart';
import 'package:greek_connect/services/user_service.dart';
import 'package:intl/intl.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  State<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends State<OrganizationSettingsScreen> {
  final UserService _userService = UserService();

  late String _currentUserId;
  List<String> _adminOrganizations = [];
  String? _selectedOrganization;
  List<UserProfile> _organizationMembers = [];
  int _adminCount = 0;

  bool _isLoading = true;
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (_currentUserId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final profile = await _userService.getUserProfile(_currentUserId);
      if (profile != null) {
        if (mounted) {
          // Get organizations where user is admin
          final adminOrgs = List<String>.from(profile.adminForOrganizations);

          setState(() {
            _adminOrganizations = adminOrgs;
            _isLoading = false;

            // Select first admin org if available
            if (_adminOrganizations.isNotEmpty) {
              _selectedOrganization = _adminOrganizations.first;
              _loadOrganizationMembers();
            }
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('Failed to load user profile');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error loading profile: $e');
      }
    }
  }

  Future<void> _loadOrganizationMembers() async {
    if (_selectedOrganization == null) return;

    setState(() => _isLoadingMembers = true);

    try {
      final members = await _userService.getOrganizationMembers(
        _selectedOrganization!,
      );
      final adminCount = await _countAdminsInOrganization(
        _selectedOrganization!,
      );

      if (mounted) {
        setState(() {
          _organizationMembers = members;
          _adminCount = adminCount;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
        _showMessage('Error loading members: $e');
      }
    }
  }

  Future<int> _countAdminsInOrganization(String organizationName) async {
    final members = await _userService.getOrganizationMembers(organizationName);
    return members
        .where((m) => m.adminForOrganizations.contains(organizationName))
        .length;
  }

  void _onOrganizationChanged(String? orgName) {
    if (orgName != null && orgName != _selectedOrganization) {
      setState(() {
        _selectedOrganization = orgName;
        _organizationMembers = [];
      });
      _loadOrganizationMembers();
    }
  }

  Future<void> _promoteUser(String targetUserId, String targetUserName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin?'),
        content: Text(
          'Make $targetUserName an admin of $_selectedOrganization?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _userService.promoteToAdmin(
        _currentUserId,
        targetUserId,
        _selectedOrganization!,
      );

      if (success) {
        _showMessage('$targetUserName is now an admin');
        await _loadOrganizationMembers();
      } else {
        _showMessage('Failed to promote user');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _demoteUser(String targetUserId, String targetUserName) async {
    final isCurrentUser = targetUserId == _currentUserId;

    // Prevent demotion if it would leave fewer than 2 admins
    if (_adminCount <= 2) {
      final errorMsg = isCurrentUser
          ? 'Cannot remove your own admin privileges. $_selectedOrganization must have at least 2 admins.'
          : 'Cannot demote $targetUserName. $_selectedOrganization must have at least 2 admins.';

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Demote'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // For self-demotion, add additional warning
    final message = isCurrentUser
        ? 'Remove your own admin privileges for $_selectedOrganization? You will become a regular member.'
        : 'Remove admin privileges from $targetUserName? They will become a regular member of $_selectedOrganization.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin Privileges?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _userService.demoteFromAdmin(
        _currentUserId,
        targetUserId,
        _selectedOrganization!,
      );

      if (success) {
        _showMessage('$targetUserName is no longer an admin');
        await _loadOrganizationMembers();
      } else {
        _showMessage(
          'Failed to demote user. Organization must have at least 2 admins.',
        );
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _removeUser(String targetUserId, String targetUserName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Organization?'),
        content: Text(
          'Remove $targetUserName from $_selectedOrganization entirely? They will not be able to access organization content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _userService.removeUserFromOrganization(
        _currentUserId,
        targetUserId,
        _selectedOrganization!,
      );

      if (success) {
        _showMessage('$targetUserName has been removed');
        await _loadOrganizationMembers();
      } else {
        _showMessage('Failed to remove user');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  bool _isUserAdmin(UserProfile user) {
    return user.adminForOrganizations.contains(_selectedOrganization);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _adminOrganizations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No Organizations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You are not an admin of any organizations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Organization Dropdown
                  const Text(
                    'Select Organization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedOrganization,
                    isExpanded: true,
                    items: _adminOrganizations.map((org) {
                      return DropdownMenuItem<String>(
                        value: org,
                        child: Text(org),
                      );
                    }).toList(),
                    onChanged: _onOrganizationChanged,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF801C0D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_organizationMembers.length} members',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF801C0D),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_isLoadingMembers)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_organizationMembers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: const Text(
                          'No members found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _organizationMembers.length,
                      itemBuilder: (context, index) {
                        final member = _organizationMembers[index];
                        final isAdmin = _isUserAdmin(member);
                        final isCurrentUser = member.uid == _currentUserId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Member info (name, email, join date)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              member.displayName ?? 'No name',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (isAdmin)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Chip(
                                                label: Text('Admin'),
                                                backgroundColor: Color(
                                                  0xFF801C0D,
                                                ),
                                                labelStyle: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (isCurrentUser)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Text(
                                            '(You)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 3),
                                      Text(
                                        member.email,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Joined ${_formatDate(member.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Action buttons (compact)
                                Column(
                                  children: [
                                    if (!isAdmin)
                                      SizedBox(
                                        height: 28,
                                        child: ElevatedButton(
                                          onPressed: () => _promoteUser(
                                            member.uid,
                                            member.displayName ?? member.email,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF801C0D,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                          ),
                                          child: const Text(
                                            'Promote',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 28,
                                        child: ElevatedButton(
                                          onPressed: _adminCount <= 2
                                              ? null
                                              : () => _demoteUser(
                                                  member.uid,
                                                  member.displayName ??
                                                      member.email,
                                                ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            disabledBackgroundColor:
                                                Colors.grey.shade300,
                                          ),
                                          child: const Text(
                                            'Demote',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 3),
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton(
                                        onPressed: () => _removeUser(
                                          member.uid,
                                          member.displayName ?? member.email,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                        ),
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(fontSize: 10),
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
