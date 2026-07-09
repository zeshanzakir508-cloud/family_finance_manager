// lib/screens/family/family_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADDED
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/family_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({Key? key}) : super(key: key);

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCurrency = 'PKR';
  bool _isLoading = false;
  List<String> _availableCurrencies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCurrencies() {
    final currencyProvider = context.read<CurrencyProvider>();
    _availableCurrencies = currencyProvider.getCurrencyList()
        .map((c) => c.code)
        .toList();
    _selectedCurrency = currencyProvider.currentCurrency;
  }

  // ✅ FIXED: Generate family code
  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[DateTime.now().millisecondsSinceEpoch % chars.length];
    }
    return code;
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final familyProvider = context.read<FamilyProvider>();
      final auth = context.read<AuthProvider>();
      
      // ✅ FIXED: Generate family code
      final familyCode = _generateFamilyCode();
      
      final family = FamilyModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: auth.userId,
        familyCode: familyCode,
        createdAt: DateTime.now(),
        settings: FamilySettings(currency: _selectedCurrency),
        members: [
          FamilyMember(
            userId: auth.userId,
            displayName: auth.userName,
            email: auth.userEmail,
            role: 'admin',
            joinedAt: DateTime.now(),
            isActive: true,
          ),
        ],
        memberIds: [auth.userId],
        totalBalance: 0.0,
        isActive: true,
      );

      // ✅ FIXED: Await and handle result
      final success = await familyProvider.createFamilyInFirestore(family);
      
      if (success != null && mounted) {
        CustomSnackBar.show(
          context,
          'Family created successfully! 🎉',
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to create family');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to create family: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Family'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createFamily,
            child: Text(
              'Create',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.family_restroom,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create a Family',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Invite members and manage finances together',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Family Name
              CustomTextField(
                controller: _nameController,
                label: 'Family Name',
                hint: 'e.g., Smith Family',
                prefixIcon: Icons.family_restroom,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a family name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'e.g., Our family budget and expenses',
                prefixIcon: Icons.description,
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Currency
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Family Currency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                items: _availableCurrencies.map((code) {
                  return DropdownMenuItem(
                    value: code,
                    child: Text('$code - ${context.read<CurrencyProvider>().getNameForCode(code)}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will be the admin of this family. You can invite members after creation.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Create Button
              CustomButton(
                onPressed: _isLoading ? null : _createFamily,
                text: 'Create Family',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.add,
              ),
              const SizedBox(height: 12),

              // Join Family link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have a family?',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/join_family');
                    },
                    child: const Text('Join Instead'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
