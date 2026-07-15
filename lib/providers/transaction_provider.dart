// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart'; // ✅ Uses AppAuthProvider
import 'family_provider.dart';
import 'mode_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;
  String? _error;
  
  String? _filterCategory;
  String? _filterType;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _searchQuery;

  // ✅ FIXED: Changed AuthProvider to AppAuthProvider
  TransactionProvider({
    AppAuthProvider? authProvider,
    FamilyProvider? familyProvider,
    ModeProvider? modeProvider,
  }) {
    if (authProvider != null && authProvider.isAuthenticated) {
      loadTransactions(authProvider.userId);
    }
  }

  // ... rest of the code remains exactly the same ...
}
