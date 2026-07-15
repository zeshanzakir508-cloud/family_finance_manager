// lib/screens/family/family_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/currency_provider.dart';
import '../../models/family_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';

class FamilyCreationScreen extends StatefulWidget {
  const FamilyCreationScreen({Key? key}) : super(key: key);

  @override
  State<FamilyCreationScreen> createState() => _FamilyCreationScreenState();
}

class _FamilyCreationScreenState extends State<FamilyCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCurrency = 'PKR';
  bool _isLoading = false;
  List<CurrencyOption> _currencies = [];

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
    final available = currencyProvider.getCurrencyList();
    _currencies = available.map((c) => CurrencyOption(
      code: c.code,
      name: c.name,
      symbol: c.symbol,
    )).toList();
    _selectedCurrency = currencyProvider.currentCurrency;
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: Changed AuthProvider to AppAuthProvider
      final auth = context.read<AppAuthProvider>();
      final familyProvider = context.read<FamilyProvider>();
      
      final family = FamilyModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: auth.userId,
        familyCode: '',
        createdAt: DateTime.now(),
        settings: FamilySettings(currency: _selectedCurrency),
        members: [],
        memberIds: [auth.userId],
      );

      familyProvider.createFamily(family);
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Family created successfully! 🎉',
        );
        Navigator.pop(context, true);
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Your Family Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a family to manage finances together',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _nameController,
                label: 'Family Name',
                hint: 'e.g., The Smiths',
                prefixIcon: Icons.family_restroom,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a family name';
                  }
                  if (value.length < 3) {
                    return 'Family name must be at least 3 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'e.g., Our family budget and expenses',
                prefixIcon: Icons.description,
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Family Currency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                items: _currencies.map((c) {
                  return DropdownMenuItem(
                    value: c.code,
                    child: Text('${c.symbol} ${c.code} - ${c.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What you get:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      icon: Icons.people,
                      text: 'Add up to 10 family members',
                    ),
                    _buildFeatureItem(
                      icon: Icons.attach_money,
                      text: 'Shared family budget tracking',
                    ),
                    _buildFeatureItem(
                      icon: Icons.analytics,
                      text: 'Family spending reports',
                    ),
                    _buildFeatureItem(
                      icon: Icons.shield,
                      text: 'Admin controls for member management',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                onPressed: _isLoading ? null : _createFamily,
                text: 'Create Family',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.add,
              ),
              const SizedBox(height: 12),

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

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA CLASS
// ============================================================

class CurrencyOption {
  final String code;
  final String name;
  final String symbol;

  CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });
}
