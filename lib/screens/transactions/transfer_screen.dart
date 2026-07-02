import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transfer_model.dart';
import '../../models/user_model.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedFromMember;
  String? _selectedToMember;
  bool _isLoading = false;
  List<UserModel> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;
    
    if (family != null && family.memberIds != null) {
      final members = <UserModel>[];
      for (var id in family.memberIds!) {
        final user = await DatabaseService.getUser(id);
        if (user != null) members.add(user);
      }
      setState(() => _members = members);
    }
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFromMember == _selectedToMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot transfer to yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final userId = authService.userId;
      final family = familyProvider.currentFamily;

      if (userId == null) throw Exception('Not logged in');
      if (family == null) throw Exception('No family found');

      final amount = double.parse(_amountController.text);

      final transfer = TransferModel(
        id: Helpers.generateId(),
        familyId: family.id!,
        fromMemberId: _selectedFromMember!,
        toMemberId: _selectedToMember!,
        amount: amount,
        currency: family.baseCurrency ?? 'USD',
        status: 'pending',
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        createdBy: userId,
      );

      await DatabaseService.saveTransfer(transfer);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer initiated! Waiting for approval.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final family = familyProvider.currentFamily;

    if (family == null || _members.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transfer Money'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No family members found. Add members first.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Transfer Money'),
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
                    // From Member
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedFromMember,
                      items: _members.map((member) {
                        return DropdownMenuItem(
                          value: member.id,
                          child: Text(member.displayName ?? 'Unknown'),  // ✅ FIXED
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedFromMember = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Please select sender';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // To Member
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        prefixIcon: Icon(Icons.person_add),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedToMember,
                      items: _members.map((member) {
                        return DropdownMenuItem(
                          value: member.id,
                          child: Text(member.displayName ?? 'Unknown'),  // ✅ FIXED
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedToMember = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Please select receiver';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: family.baseCurrency ?? 'USD',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transfers require approval from the receiver. '
                        'You will be notified when approved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Transfer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
