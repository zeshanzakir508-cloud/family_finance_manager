import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/transaction_model.dart';
import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = 'expense'; // 'income' or 'expense'
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedMemberId;
  String? _selectedMemberName;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final userId = authService.userId;
    final isFamilyMode = modeProvider.isFamilyMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveTransaction(userId),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFamilyMode
                          ? Colors.teal.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFamilyMode ? 'Family Transaction' : 'Personal Transaction',
                      style: AppTheme.bodyStyle.copyWith(
                        color: isFamilyMode ? Colors.teal : AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type Toggle
                  _buildTypeToggle(),
                  const SizedBox(height: 24),

                  // Member Selector (Family Mode Only)
                  if (isFamilyMode && familyProvider.hasFamily)
                    _buildMemberSelector(familyProvider),
                  if (isFamilyMode && familyProvider.hasFamily)
                    const SizedBox(height: 16),

                  // Amount
                  _buildAmountField(),
                  const SizedBox(height: 16),

                  // Category
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Description
                  _buildDescriptionField(),
                  const SizedBox(height: 16),

                  // Date
                  _buildDatePicker(),
                  const SizedBox(height: 16),

                  // Notes
                  _buildNotesField(),
                  const SizedBox(height: 24),

                  // Save Button
                  _buildSaveButton(userId),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          _buildTypeButton('expense', 'Expense', Colors.red),
          _buildTypeButton('income', 'Income', Colors.green),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String value, String label, Color color) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = value;
            _selectedCategory = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value == 'expense' ? Icons.arrow_downward : Icons.arrow_upward,
                color: isSelected ? color : AppTheme.textSecondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  color: isSelected ? color : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberSelector(FamilyProvider familyProvider) {
    final members = familyProvider.familyMembers;

    return DropdownButtonFormField<String>(
      value: _selectedMemberId,
      decoration: InputDecoration(
        labelText: 'Select Member *',
        hintText: 'Who is this transaction for?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      items: members.map((member) {
        return DropdownMenuItem<String>(
          value: member.id,
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  member.initials,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(member.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedMemberId = value;
          final member = members.firstWhere((m) => m.id == value);
          _selectedMemberName = member.displayName;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a member';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount *',
        hintText: '0.00',
        prefixText: '\$ ',
        prefixStyle: AppTheme.bodyStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      style: AppTheme.headingStyle.copyWith(fontSize: 24),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _selectedType == 'income'
        ? Constants.incomeCategories
        : Constants.expenseCategories;

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
        hintText: 'Select a category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description *',
        hintText: 'What was this transaction for?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.surfaceColor,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: AppTheme.bodyStyle,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional notes',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildSaveButton(String? userId) {
    final isFamilyMode = Provider.of<ModeProvider>(context).isFamilyMode;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _saveTransaction(userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedType == 'income'
              ? Colors.green
              : Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Add ${_selectedType == 'income' ? 'Income' : 'Expense'}',
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction(String? userId) async {
    // Validate
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final isFamilyMode = modeProvider.isFamilyMode;

    if (isFamilyMode && _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = TransactionModel(
        id: Helpers.generateId(),
        userId: userId,
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        type: _selectedType,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        familyId: isFamilyMode ? familyProvider.currentFamily?.id : null,
        memberId: isFamilyMode ? _selectedMemberId : null,
        memberName: isFamilyMode ? _selectedMemberName : null,
        isFamilyTransaction: isFamilyMode,
      );

      await DatabaseService.saveTransaction(transaction);

      // Create notification
      if (userId != null) {
        await NotificationService.notifyTransactionAdded(userId, transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedType == 'income' ? 'Income' : 'Expense'} added successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
