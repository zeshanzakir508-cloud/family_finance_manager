import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class FamilyCreationScreen extends StatefulWidget {
  const FamilyCreationScreen({super.key});

  @override
  State<FamilyCreationScreen> createState() => _FamilyCreationScreenState();
}

class _FamilyCreationScreenState extends State<FamilyCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCurrency = 'USD';
  bool _isLoading = false;

  final List<String> _currencies = ['USD', 'PKR', 'SAR', 'BHD', 'AED', 'EUR', 'GBP', 'INR'];

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

      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      
      await familyProvider.createFamily(
        _nameController.text.trim(),
        userId,
        description: _descriptionController.text.trim(),
        baseCurrency: _selectedCurrency,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Family'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Family Name',
                        prefixIcon: Icon(Icons.family_restroom),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a family name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Base Currency',
                        prefixIcon: Icon(Icons.currency_exchange),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text('$currency (${_getCurrencySymbol(currency)})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCurrency = value!);
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    Text(
                      'All family transactions will be stored in this currency',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'What happens next?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• You will be the admin of this family\n'
                      '• A unique family code will be generated\n'
                      '• Share the code with family members to join\n'
                      '• You can add members from contacts',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Family'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrencySymbol(String code) {
    const symbols = {
      'USD': '\$', 'PKR': 'Rs', 'SAR': '﷼', 'BHD': 'د.ب',
      'AED': 'د.إ', 'EUR': '€', 'GBP': '£', 'INR': '₹',
    };
    return symbols[code] ?? code;
  }
}
