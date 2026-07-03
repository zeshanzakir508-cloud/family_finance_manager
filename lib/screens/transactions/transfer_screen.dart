// lib/screens/transactions/transfer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/transfer_model.dart';
import '../../models/family_model.dart';  // <-- ADD THIS IMPORT
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedFromMember;
  String? _selectedToMember;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isRecurring = false;
  String _recurringType = 'weekly';
  
  late TabController _tabController;
  List<TransferModel> _transfers = [];

  final List<Map<String, dynamic>> _recurringOptions = [
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransfers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTransfers() async {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final currentFamily = familyProvider.currentFamily;
    
    if (currentFamily != null) {
      _transfers = await DatabaseService.getFamilyTransfers(currentFamily.id!);
      setState(() {});
    }
  }

  Future<void> _createTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFromMember == _selectedToMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sender and receiver cannot be the same'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final userId = authService.userId;
      final currentFamily = familyProvider.currentFamily;
      
      if (userId == null || currentFamily == null) {
        throw Exception('No family found');
      }

      // Get member names using the members list from Family
      String fromUserName = 'Unknown';
      String toUserName = 'Unknown';
      
      if (currentFamily.members != null) {
        final fromMember = currentFamily.members!.firstWhere(
          (m) => m.id == _selectedFromMember,
          orElse: () => FamilyMember(
            id: '', 
            userId: '', 
            displayName: 'Unknown', 
            email: '', 
            role: 'member', 
            joinedAt: DateTime.now(), 
            isActive: true
          ),
        );
        final toMember = currentFamily.members!.firstWhere(
          (m) => m.id == _selectedToMember,
          orElse: () => FamilyMember(
            id: '', 
            userId: '', 
            displayName: 'Unknown', 
            email: '', 
            role: 'member', 
            joinedAt: DateTime.now(), 
            isActive: true
          ),
        );
        fromUserName = fromMember.displayName;
        toUserName = toMember.displayName;
      }

      final transfer = TransferModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        familyId: currentFamily.id!,
        fromUserId: _selectedFromMember!,
        toUserId: _selectedToMember!,
        fromUserName: fromUserName,
        toUserName: toUserName,
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        status: 'pending',
        isRecurring: _isRecurring,
        recurringType: _isRecurring ? _recurringType : null,
        createdBy: userId,
        createdAt: DateTime.now(),
      );

      await DatabaseService.createTransfer(transfer);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer created successfully! ⏳ Waiting for approval'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        _loadTransfers();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    _selectedFromMember = null;
    _selectedToMember = null;
    _isRecurring = false;
    setState(() {});
  }

  Future<void> _approveTransfer(TransferModel transfer) async {
    setState(() => _isLoading = true);
    
    try {
      final updatedTransfer = transfer.copyWith(status: 'approved');
      await DatabaseService.updateTransfer(updatedTransfer);
      _loadTransfers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer approved ✅'),
          backgroundColor: Colors.green,
        ),
      );
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

  Future<void> _rejectTransfer(TransferModel transfer) async {
    setState(() => _isLoading = true);
    
    try {
      final updatedTransfer = transfer.copyWith(status: 'rejected');
      await DatabaseService.updateTransfer(updatedTransfer);
      _loadTransfers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer rejected ❌'),
          backgroundColor: Colors.orange,
        ),
      );
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
    final familyProvider = Provider.of<FamilyProvider>(context);
    final members = familyProvider.getFamilyMembers();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Transfer Money'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Transfer'),
            Tab(text: 'History'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewTransferTab(members),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildNewTransferTab(List<FamilyMember> members) {
    return SingleChildScrollView(
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transfer Money',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Transfer between family members',
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
            ),
            const SizedBox(height: 16),

            // From Member
            _buildMemberSelector(
              label: 'From',
              hint: 'Select sender',
              members: members,
              selectedId: _selectedFromMember,
              onChanged: (value) {
                setState(() => _selectedFromMember = value);
              },
            ),
            const SizedBox(height: 16),

            // To Member
            _buildMemberSelector(
              label: 'To',
              hint: 'Select receiver',
              members: members,
              selectedId: _selectedToMember,
              onChanged: (value) {
                setState(() => _selectedToMember = value);
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
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
            ),
            const SizedBox(height: 16),

            // Date
            _buildDatePicker(),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Recurring Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: _isRecurring ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recurring Transfer',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _isRecurring
                                ? '$_recurringType transfer will repeat'
                                : 'One-time transfer only',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() => _isRecurring = value);
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Recurring Type
            if (_isRecurring)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _recurringType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  items: _recurringOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'] as String,
                      child: Text(option['label'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _recurringType = value!);
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Transfer Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
                      'Send Transfer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelector({
    required String label,
    required String hint,
    required List<FamilyMember> members,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
            value: selectedId,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            hint: Text(hint),
            items: members.map((member) {
              return DropdownMenuItem<String>(
                value: member.id,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(member.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a member';
              }
              return null;
            },
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
            const Icon(Icons.calendar_today, color: Colors.orange),
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

  Widget _buildHistoryTab() {
    if (_transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No transfers yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first transfer',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transfers.length,
      itemBuilder: (context, index) {
        final transfer = _transfers[index];
        final isPending = transfer.status == 'pending';
        final isApproved = transfer.status == 'approved';
        final isRejected = transfer.status == 'rejected';
        
        Color statusColor;
        IconData statusIcon;
        String statusText;
        
        if (isPending) {
          statusColor = Colors.orange;
          statusIcon = Icons.pending;
          statusText = 'Pending';
        } else if (isApproved) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'Approved';
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
          statusText = 'Rejected';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            title: Text(
              '${transfer.fromUserName} → ${transfer.toUserName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.description ?? 'Transfer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(transfer.date),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helpers.formatCurrency(transfer.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              if (isPending) {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transfer Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('From', transfer.fromUserName),
                        _buildDetailRow('To', transfer.toUserName),
                        _buildDetailRow('Amount', Helpers.formatCurrency(transfer.amount)),
                        _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(transfer.date)),
                        if (transfer.description != null)
                          _buildDetailRow('Description', transfer.description!),
                        _buildDetailRow('Status', statusText),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                ),
                                child: const Text('Close'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _approveTransfer(transfer);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _rejectTransfer(transfer);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
