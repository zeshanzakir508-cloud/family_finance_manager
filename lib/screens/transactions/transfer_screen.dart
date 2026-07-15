// lib/screens/transactions/transfer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/currency_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/family_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/amount_input.dart';
import 'widgets/date_time_picker.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({Key? key}) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _amount = 0.0;
  String? _fromMemberId;
  String? _toMemberId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<FamilyMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadMembers() {
    final familyProvider = context.read<FamilyProvider>();
    _members = familyProvider.getFamilyMembers();
    
    final auth = context.read<AppAuthProvider>();
    if (_members.isNotEmpty) {
      final currentMember = _members.firstWhere(
        (m) => m.userId == auth.userId,
        orElse: () => _members.first,
      );
      setState(() {
        _fromMemberId = currentMember.userId;
        final toMember = _members.firstWhere(
          (m) => m.userId != _fromMemberId,
          orElse: () => _members.first,
        );
        if (toMember.userId != _fromMemberId) {
          _toMemberId = toMember.userId;
        }
      });
    }
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromMemberId == _toMemberId) {
      CustomSnackBar.show(
        context,
        'Cannot transfer to yourself',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AppAuthProvider>();
      final familyProvider = context.read<FamilyProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      final fromMember = _members.firstWhere((m) => m.userId == _fromMemberId);
      final toMember = _members.firstWhere((m) => m.userId == _toMemberId);
      
      final transaction = TransactionModel(
        id: '',
        userId: auth.userId,
        familyId: familyProvider.currentFamily?.id,
        amount: _amount,
        category: 'Transfer',
        description: _descriptionController.text.trim(),
        type: 'transfer',
        date: _selectedDate,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        isFamilyTransaction: true,
        sourceMemberId: _fromMemberId,
        sourceMemberName: fromMember.displayName,
        memberId: _toMemberId,
        memberName: toMember.displayName,
        transferId: DateTime.now().millisecondsSinceEpoch.toString(),
        transferStatus: 'pending',
      );

      // ✅ Using addTransaction method
      final success = await transactionProvider.addTransaction(transaction);
      
      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Transfer initiated successfully! 💸',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to transfer: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitTransfer,
            child: Text(
              'Send',
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
              AmountInput(
                label: 'Amount',
                currency: currencyProvider.currentCurrency,
                onAmountChanged: (value) {
                  setState(() {
                    _amount = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _fromMemberId,
                decoration: const InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: _members.map((member) {
                  return DropdownMenuItem(
                    value: member.userId,
                    child: Text(member.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _fromMemberId = value;
                    if (_toMemberId == value) {
                      final toMember = _members.firstWhere(
                        (m) => m.userId != value,
                        orElse: () => _members.first,
                      );
                      _toMemberId = toMember.userId;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a sender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _toMemberId,
                decoration: const InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_add),
                ),
                items: _members
                    .where((m) => m.userId != _fromMemberId)
                    .map((member) {
                  return DropdownMenuItem(
                    value: member.userId,
                    child: Text(member.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _toMemberId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a receiver';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'e.g., Pocket money, Sharing bill',
                prefixIcon: Icons.description,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              DateTimePicker(
                label: 'Date',
                initialDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Add any additional notes',
                prefixIcon: Icons.note,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              
              CustomButton(
                onPressed: _isLoading ? null : _submitTransfer,
                text: 'Send Money',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
