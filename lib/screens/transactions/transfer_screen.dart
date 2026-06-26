import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/transfer_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _fromMemberId;
  String? _toMemberId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final members = familyProvider.familyMembers;
    final userId = authService.userId;

    if (_fromMemberId == null && userId != null) {
      _fromMemberId = userId;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Transfer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sendTransfer,
            child: Text(
              'Send',
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Transfer will need approval from the receiver to complete.',
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  _buildFromDropdown(members, userId),
                  const SizedBox(height: 16),

                  _buildToDropdown(members, userId),
                  const SizedBox(height: 16),

                  _buildAmountField(),
                  const SizedBox(height: 16),

                  _buildNoteField(),
                  const SizedBox(height: 24),

                  _buildSendButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildFromDropdown(List<UserModel> members, String? userId) {
    return DropdownButtonFormField<String>(
      value: _fromMemberId,
      decoration: const InputDecoration(
        labelText: 'From *',
        hintText: 'Select sender',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: members.map((member) {
        final isCurrentUser = member.id == userId;
        return DropdownMenuItem<String>(
          value: member.id,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  member.initials,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(member.displayName),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'You',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _fromMemberId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a sender';
        }
        return null;
      },
    );
  }

  Widget _buildToDropdown(List<UserModel> members, String? userId) {
    final filteredMembers = members.where((m) => m.id != userId).toList();

    return DropdownButtonFormField<String>(
      value: _toMemberId,
      decoration: const InputDecoration(
        labelText: 'To *',
        hintText: 'Select receiver',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: filteredMembers.map((member) {
        return DropdownMenuItem<String>(
          value: member.id,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  member.initials,
                  style: TextStyle(
                    fontSize: 12,
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
          _toMemberId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a receiver';
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

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Note (Optional)',
        hintText: 'Add a note for this transfer',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _sendTransfer,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Request Transfer',
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _sendTransfer() async {
    if (_fromMemberId == null) {
      setState(() {
        _errorMessage = 'Please select a sender';
      });
      return;
    }

    if (_toMemberId == null) {
      setState(() {
        _errorMessage = 'Please select a receiver';
      });
      return;
    }

    if (_fromMemberId == _toMemberId) {
      setState(() {
        _errorMessage = 'Sender and receiver cannot be the same';
      });
      return;
    }

    if (_amountController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an amount';
      });
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final userId = authService.userId;

      final fromMember = DatabaseService.getUser(_fromMemberId!);
      final toMember = DatabaseService.getUser(_toMemberId!);
      final family = familyProvider.currentFamily;

      if (fromMember == null || toMember == null || family == null) {
        throw Exception('Invalid member or family');
      }

      final transfer = TransferModel(
        id: Helpers.generateId(),
        familyId: family.id,
        fromMemberId: _fromMemberId,
        fromMemberName: fromMember.displayName,
        toMemberId: _toMemberId,
        toMemberName: toMember.displayName,
        amount: amount,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        status: TransferStatus.pending,
        createdAt: DateTime.now(),
      );

      await DatabaseService.saveTransfer(transfer);
      await NotificationService.notifyTransferRequest(transfer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer request sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }
}
