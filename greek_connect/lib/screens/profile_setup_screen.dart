import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greek_connect/models/user_profile.dart';
import 'package:greek_connect/services/user_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  final String? displayName;

  const ProfileSetupScreen({super.key, required this.email, this.displayName});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final UserService _userService = UserService();
  String? _selectedOrganization;
  bool _isLoading = false;

  // List of available organizations (Greek life organizations)
  final List<String> _organizations = [
    'Alpha Phi Alpha',
    'Alpha Phi',
    'Alpha Sigma Phi',
    'Beta Theta Pi',
    'Chi Phi',
    'Chi Psi (Lodge)',
    'Delta Phi Epsilon',
    'Delta Tau Delta',
    'Kappa Sigma',
    'Lambda Sigma Upsilon',
    'Lambda Tau Omega',
    'Lambda Upsilon Lambda',
    'Nu Alpha Phi',
    'Omega Phi Beta',
    'Phi Sigma Kappa',
    'Phi Sigma Sigma',
    'Sigma Nu',
    'Sigma Delta Tau',
    'Sigma Psi Zeta',
    'Sigma Phi Epsilon',
    'Theta Phi Alpha',
    'Alpha Phi Omega',
    'Other',
  ];

  Future<void> _completeSetup() async {
    if (_selectedOrganization == null) {
      _showMessage('Please select an organization');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('User not authenticated');
        return;
      }

      final profile = UserProfile(
        uid: user.uid,
        email: widget.email,
        displayName: widget.displayName,
        organization: _selectedOrganization,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      final success = await _userService.createUserProfile(profile);

      if (success) {
        // Profile created, auth stream will handle navigation
        if (mounted) {
          // The StreamBuilder in main will detect the profile and navigate
        }
      } else {
        _showMessage('Failed to create profile. Please try again.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Greek Connect!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Select Your Organization',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedOrganization,
                        hint: const Text('Choose your organization'),
                        isExpanded: true,
                        items: _organizations.map((String org) {
                          return DropdownMenuItem<String>(
                            value: org,
                            child: Text(org),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedOrganization = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _completeSetup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Complete Setup',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can update your organization later in settings.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
