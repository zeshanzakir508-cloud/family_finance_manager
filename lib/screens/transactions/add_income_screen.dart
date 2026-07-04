// lib/screens/transactions/add_income_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart';
import '../../models/family_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'salary';
  DateTime _selectedDate = DateTime.now();
  String _selectedMemberId = '';
  bool _isLoading = false;

  final List<String> _incomeCategories = [
    'salary',
    'freelance',
    'investment',
    'gift',
    'rental',
    'business',
    'refund',
    'other',
  ];

  final Map<String, IconData> _categoryIcons = {
    'salary': Icons.work,
    'freelance': Icons.computer,
    'investment': Icons.trending_up,
    'gift': Icons.card_giftcard,
    'rental': Icons.home,
    'business': Icons.storefront,
    'refund': Icons.refresh,
    'other': Icons.more_horiz,
  };

  final Map<String, String> _categoryDisplay = {
    'salary': 'Salary',
    'freelance': 'Freelance',
    'investment': 'Investment',
    'gift': 'Gift',
    'rental': 'Rental Income',
    'business': 'Business',
    'refund': 'Refund',
    'other': 'Other',
  };

  final Map<String, Color> _categoryColors = {
    'salary': Colors.blue,
    'freelance': Colors.purple,
    'investment': Colors.green,
    'gift': Colors.pink,
    'rental': Colors.orange,
    'business': Colors.teal,
    'refund': Colors.cyan,
    'other': Colors.grey,
  };

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent double submission
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final modeProvider = Provider.of<ModeProvider>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);

      final userId = authService.userId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get member name if selected
      String? memberName;
      String? memberId;
      
      if (_selectedMemberId.isNotEmpty) {
        final members = familyProvider.getFamilyMembers();
        final selectedMember = members.firstWhere(
          (m) => m.id == _selectedMemberId,
          orElse: () => FamilyMember(
            id: '',
            userId: '',
            displayName: '',
            email: '',
            role: 'member',
            joinedAt: DateTime.now(),
            isActive: true,
          ),
        );
        memberName = selectedMember.displayName;
        memberId = selectedMember.id;
      }

      final amount = double.parse(_amountController.text.trim());
      final description = _descriptionController.text.trim();

      final transaction = TransactionModel(
        userId: userId,
        type: 'income',
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        description: description.isNotEmpty ? description : null,
        memberName: memberName,
        memberId: memberId,
        familyId: modeProvider.isFamilyMode ? familyProvider.currentFamily?.id : null,
        isFamilyTransaction: modeProvider.isFamilyMode,
        createdAt: DateTime.now(),
      );

      // Save with timeout
      if (modeProvider.isPersonalMode) {
        await DatabaseService.addPersonalTransaction(transaction)
            .timeout(const Duration(seconds: 15));
      } else {
        await DatabaseService.addFamilyTransaction(transaction)
            .timeout(const Duration(seconds: 15));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income added successfully! 💰'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save income';
        if (e.toString().contains('Timeout')) {
          errorMessage = 'Connection timeout. Please check your internet and try again.';
        } else {
          errorMessage = 'Error: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final isFamilyMode = modeProvider.isFamilyMode;
    final members = familyProvider.getFamilyMembers();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Income'),
        backgroundColor: Colors.green,
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
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              if (isFamilyMode) _buildMemberSelector(members),
              if (isFamilyMode) const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildSaveButton(),
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
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_upward,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Income',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Record your earnings',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Amount *',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) {
          return 'Amount must be greater than 0';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
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
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _incomeCategories.map((category) {
              final isSelected = _selectedCategory == category;
              final color = _categoryColors[category] ?? Colors.blue;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcons[category] ?? Icons.category,
                      size: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _categoryDisplay[category] ?? category,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: color,
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('MMMM dd, yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelector(List<FamilyMember> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Member',
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
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedMemberId.isEmpty ? null : _selectedMemberId,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            hint: const Text('Select Member'),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Myself'),
              ),
              if (members.isNotEmpty)
                ...members.map((member) {
                  return DropdownMenuItem<String>(
                    value: member.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          child: Text(
                            member.displayName.isNotEmpty 
                                ? member.displayName[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(member.displayName),
                      ],
                    ),
                  );
                }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMemberId = value ?? '';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        hintText: 'Add a note about this income',
      ),
      maxLines: 2,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveIncome,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Save Income',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
