// lib/screens/family/family_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/family_model.dart';
import '../../utils/app_theme.dart';

class FamilyCreationScreen extends StatefulWidget {
  const FamilyCreationScreen({super.key});

  @override
  State<FamilyCreationScreen> createState() => _FamilyCreationScreenState();
}

class _FamilyCreationScreenState extends State<FamilyCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _allowMembersToAdd = true;
  bool _requireApproval = true;
  String _selectedCurrency = 'USD';

  final List<String> _currencies = ['USD', 'PKR', 'EUR', 'GBP', 'SAR', 'BHD', 'AED'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // ✅ Ensure profile is loaded
      if (authService.userProfile == null) {
        await authService.fetchUserProfile(userId);
      }

      final newFamily = FamilyModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        createdBy: userId,
        familyCode: _generateFamilyCode(),
        createdAt: DateTime.now(),
        members: [
          FamilyMember(
            id: userId,
            userId: userId,
            displayName: authService.userProfile?['displayName'] ?? 'You',
            email: authService.currentUser?.email ?? '',
            role: 'admin',
            joinedAt: DateTime.now(),
            isActive: true,
          ),
        ],
        memberIds: [userId],
        settings: FamilySettings(
          currency: _selectedCurrency,
          allowMembersToAdd: _allowMembersToAdd,
          requireApproval: _requireApproval,
        ),
      );

      await DatabaseService.createFamily(newFamily);
      
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      familyProvider.createFamily(newFamily);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Family "${_nameController.text.trim()}" created successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/family-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create family: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 6; i++) {
      code += chars[(now + i * 7) % chars.length];
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Family'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildCurrencySelector(),
              const SizedBox(height: 16),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              _buildCreateButton(),
              const SizedBox(height: 16),
              _buildInfoCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Your Family',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Start managing finances together',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Family Name *',
        prefixIcon: Icon(Icons.family_restroom),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        hintText: 'e.g., Smith Family',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a family name';
        }
        if (value.length < 2) {
          return 'Family name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        hintText: 'e.g., Our family finance group',
      ),
      maxLines: 2,
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            items: _currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Text(currency),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          SwitchListTile(
            secondary: Icon(
              Icons.person_add,
              color: _allowMembersToAdd ? AppTheme.primaryColor : Colors.grey,
            ),
            title: const Text('Members Can Add'),
            subtitle: const Text('Allow members to add transactions'),
            value: _allowMembersToAdd,
            onChanged: (value) {
              setState(() {
                _allowMembersToAdd = value;
              });
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          
          SwitchListTile(
            secondary: Icon(
              Icons.approval,
              color: _requireApproval ? AppTheme.primaryColor : Colors.grey,
            ),
            title: const Text('Require Approval'),
            subtitle: const Text('Transfers require admin approval'),
            value: _requireApproval,
            onChanged: (value) {
              setState(() {
                _requireApproval = value;
              });
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _createFamily,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Create Family',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You will be the admin of this family. '
              'You can manage members, approve transfers, and control settings.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
