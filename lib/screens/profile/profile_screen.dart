import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  String? _userId;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _userId = authService.userId;

    if (_userId != null) {
      final box = Hive.box<UserProfile>('userProfile');
      final user = box.get(_userId!);
      if (user != null) {
        setState(() {
          _userProfile = user;
          _fullNameController.text = user.fullName ?? '';
          _fatherNameController.text = user.fatherOrHusbandName ?? '';
          _phoneController.text = user.phoneNumber ?? '';
          _addressController.text = user.address ?? '';
          _occupationController.text = user.occupation ?? '';
          _dateOfBirthController.text = user.dateOfBirth ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final box = Hive.box<UserProfile>('userProfile');
      final updatedUser = _userProfile!.copyWith(
        fullName: _fullNameController.text.trim(),
        fatherOrHusbandName: _fatherNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        occupation: _occupationController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
      );
      
      await box.put(_userId!, updatedUser);
      
      setState(() {
        _userProfile = updatedUser;
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userEmail = authService.userEmail ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Profile' : 'Profile',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Save',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Image
                  _buildProfileImage(),
                  const SizedBox(height: 24),

                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: userEmail,
                            isEditable: false,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: _fullNameController.text,
                            controller: _fullNameController,
                            isEditable: _isEditing,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.family_restroom,
                            label: 'Father/Husband Name',
                            value: _fatherNameController.text,
                            controller: _fatherNameController,
                            isEditable: _isEditing,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            value: _phoneController.text,
                            controller: _phoneController,
                            isEditable: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.home_outlined,
                            label: 'Address',
                            value: _addressController.text,
                            controller: _addressController,
                            isEditable: _isEditing,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.work_outline,
                            label: 'Occupation',
                            value: _occupationController.text,
                            controller: _occupationController,
                            isEditable: _isEditing,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.calendar_today,
                            label: 'Date of Birth',
                            value: _dateOfBirthController.text,
                            controller: _dateOfBirthController,
                            isEditable: _isEditing,
                            isDatePicker: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Status',
                            style: AppTheme.subheadingStyle,
                          ),
                          const SizedBox(height: 12),
                          _buildStatusTile(
                            label: 'Email Verified',
                            value: _userProfile?.isEmailVerified ?? false,
                          ),
                          const SizedBox(height: 8),
                          _buildStatusTile(
                            label: 'Account Approved',
                            value: _userProfile?.isApproved ?? false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            _userProfile?.initials ?? 'U',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
    TextInputType keyboardType = TextInputType.text,
    bool isDatePicker = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.captionStyle,
              ),
              const SizedBox(height: 4),
              isEditable
                  ? isDatePicker
                      ? GestureDetector(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                controller?.text = 
                                    '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.dividerColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              value.isEmpty ? 'Tap to select date' : value,
                              style: AppTheme.bodyStyle.copyWith(
                                color: value.isEmpty 
                                    ? AppTheme.textSecondaryColor 
                                    : null,
                              ),
                            ),
                          ),
                        )
                      : TextFormField(
                          controller: controller,
                          keyboardType: keyboardType,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: AppTheme.bodyStyle,
                        )
                  : Text(
                      value.isEmpty ? 'Not set' : value,
                      style: AppTheme.bodyStyle.copyWith(
                        color: value.isEmpty 
                            ? AppTheme.textSecondaryColor 
                            : null,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTile({
    required String label,
    required bool value,
  }) {
    return Row(
      children: [
        Icon(
          value ? Icons.check_circle : Icons.pending_outlined,
          color: value ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTheme.bodyStyle,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: value ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value ? 'Verified' : 'Pending',
            style: TextStyle(
              color: value ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }
}
