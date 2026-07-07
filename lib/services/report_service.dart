// lib/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransactionService _transactionService = TransactionService();

  // ============================================================
  // GENERATE REPORTS
  // ============================================================

  Future<ReportModel> generateSpendingBreakdown({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    try {
      final transactions = await _transactionService.filterTransactions(
        userId: userId,
        familyId: familyId,
        startDate: startDate,
        endDate: endDate,
      );

      final expenseTransactions = transactions.where((t) => t.isExpense).toList();
      final categoryTotals = <String, double>{};
      double totalExpense = 0.0;

      for (var t in expenseTransactions) {
        final category = t.category ?? 'Other';
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + t.amount!;
        totalExpense += t.amount!;
      }

      // Sort categories by amount descending
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final data = {
        'totalExpense': totalExpense,
        'transactionCount': expenseTransactions.length,
        'categoryCount': categoryTotals.length,
        'categories': {
          for (var entry in sortedCategories) entry.key: entry.value,
        },
        'topCategories': sortedCategories.take(5).map((e) => e.key).toList(),
        'biggestCategory': sortedCategories.isNotEmpty ? sortedCategories.first.key : null,
        'biggestAmount': sortedCategories.isNotEmpty ? sortedCategories.first.value : 0.0,
      };

      return ReportModel(
        id: '',
        userId: userId,
        familyId: familyId,
        type: ReportType.spendingBreakdown,
        name: 'Spending Breakdown',
        description: '${startDate.toLocal()} to ${endDate.toLocal()}',
        startDate: startDate,
        endDate: endDate,
        data: data,
        generatedAt: DateTime.now(),
        generatedBy: userId,
      );
    } catch (e) {
      throw Exception('Failed to generate spending breakdown: $e');
    }
  }

  Future<ReportModel> generateIncomeVsExpense({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    try {
      final transactions = await _transactionService.filterTransactions(
        userId: userId,
        familyId: familyId,
        startDate: startDate,
        endDate: endDate,
      );

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      int incomeCount = 0;
      int expenseCount = 0;

      for (var t in transactions) {
        if (t.isIncome) {
          totalIncome += t.amount!;
          incomeCount++;
        } else if (t.isExpense) {
          totalExpense += t.amount!;
          expenseCount++;
        }
      }

      final netAmount = totalIncome - totalExpense;

      final data = {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netAmount': netAmount,
        'incomeCount': incomeCount,
        'expenseCount': expenseCount,
        'totalCount': transactions.length,
        'isPositive': netAmount >= 0,
      };

      return ReportModel(
        id: '',
        userId: userId,
        familyId: familyId,
        type: ReportType.incomeVsExpense,
        name: 'Income vs Expense',
        description: '${startDate.toLocal()} to ${endDate.toLocal()}',
        startDate: startDate,
        endDate: endDate,
        data: data,
        generatedAt: DateTime.now(),
        generatedBy: userId,
      );
    } catch (e) {
      throw Exception('Failed to generate income vs expense: $e');
    }
  }

  Future<ReportModel> generateMonthlyTrends({
    required String userId,
    required int year,
    String? familyId,
  }) async {
    try {
      final monthlyData = <String, Map<String, double>>{};

      for (int month = 1; month <= 12; month++) {
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(year, month + 1, 1);

        final transactions = await _transactionService.filterTransactions(
          userId: userId,
          familyId: familyId,
          startDate: startDate,
          endDate: endDate,
        );

        double income = 0.0;
        double expense = 0.0;

        for (var t in transactions) {
          if (t.isIncome) {
            income += t.amount!;
          } else if (t.isExpense) {
            expense += t.amount!;
          }
        }

        final monthKey = '${year}-${month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] = {
          'income': income,
          'expense': expense,
          'net': income - expense,
        };
      }

      // Calculate totals
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      for (var data in monthlyData.values) {
        totalIncome += data['income']!;
        totalExpense += data['expense']!;
      }

      final data = {
        'year': year,
        'monthlyData': monthlyData,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netAmount': totalIncome - totalExpense,
        'bestMonth': _findBestMonth(monthlyData),
        'worstMonth': _findWorstMonth(monthlyData),
      };

      return ReportModel(
        id: '',
        userId: userId,
        familyId: familyId,
        type: ReportType.monthlyTrends,
        name: 'Monthly Trends $year',
        description: 'Full year $year',
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
        data: data,
        generatedAt: DateTime.now(),
        generatedBy: userId,
      );
    } catch (e) {
      throw Exception('Failed to generate monthly trends: $e');
    }
  }

  Future<ReportModel> generateCategoryWiseSpending({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    try {
      final transactions = await _transactionService.filterTransactions(
        userId: userId,
        familyId: familyId,
        startDate: startDate,
        endDate: endDate,
      );

      final expenseTransactions = transactions.where((t) => t.isExpense).toList();
      final categorySpending = <String, Map<String, dynamic>>{};

      for (var t in expenseTransactions) {
        final category = t.category ?? 'Other';
        if (!categorySpending.containsKey(category)) {
          categorySpending[category] = {
            'total': 0.0,
            'count': 0,
            'average': 0.0,
            'min': double.infinity,
            'max': 0.0,
            'transactions': <Map<String, dynamic>>[],
          };
        }

        final catData = categorySpending[category]!;
        catData['total'] = (catData['total'] ?? 0.0) + t.amount!;
        catData['count'] = (catData['count'] ?? 0) + 1;
        catData['min'] = (catData['min'] ?? double.infinity) < t.amount! 
            ? (catData['min'] ?? double.infinity) 
            : t.amount!;
        catData['max'] = (catData['max'] ?? 0.0) > t.amount! 
            ? (catData['max'] ?? 0.0) 
            : t.amount!;
        catData['transactions']?.add({
          'id': t.id,
          'amount': t.amount,
          'description': t.description,
          'date': t.date?.toIso8601String(),
        });
      }

      // Calculate averages
      for (var key in categorySpending.keys) {
        final catData = categorySpending[key]!;
        catData['average'] = catData['total'] / catData['count'];
      }

      // Sort categories by total descending
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value['total'].compareTo(a.value['total']));

      final totalSpending = sortedCategories.fold<double>(
        0.0,
        (sum, entry) => sum + entry.value['total'],
      );

      final data = {
        'totalSpending': totalSpending,
        'categoryCount': categorySpending.length,
        'transactionCount': expenseTransactions.length,
        'categories': categorySpending,
        'topCategories': sortedCategories.take(5).map((e) => e.key).toList(),
      };

      return ReportModel(
        id: '',
        userId: userId,
        familyId: familyId,
        type: ReportType.categoryWise,
        name: 'Category-wise Spending',
        description: '${startDate.toLocal()} to ${endDate.toLocal()}',
        startDate: startDate,
        endDate: endDate,
        data: data,
        generatedAt: DateTime.now(),
        generatedBy: userId,
      );
    } catch (e) {
      throw Exception('Failed to generate category-wise spending: $e');
    }
  }

  Future<ReportModel> generateCashFlow({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    try {
      final transactions = await _transactionService.filterTransactions(
        userId: userId,
        familyId: familyId,
        startDate: startDate,
        endDate: endDate,
      );

      // Group by month
      final monthlyData = <String, Map<String, double>>{};
      
      for (var t in transactions) {
        final monthKey = '${t.date!.year}-${t.date!.month.toString().padLeft(2, '0')}';
        
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {'income': 0.0, 'expense': 0.0, 'net': 0.0};
        }

        if (t.isIncome) {
          monthlyData[monthKey]!['income'] = 
              (monthlyData[monthKey]!['income'] ?? 0.0) + t.amount!;
        } else if (t.isExpense) {
          monthlyData[monthKey]!['expense'] = 
              (monthlyData[monthKey]!['expense'] ?? 0.0) + t.amount!;
        }

        monthlyData[monthKey]!['net'] = 
            (monthlyData[monthKey]!['income'] ?? 0.0) - 
            (monthlyData[monthKey]!['expense'] ?? 0.0);
      }

      // Calculate cash flow trends
      double cumulative = 0.0;
      final cashFlowTrends = <String, double>{};
      
      for (var entry in monthlyData.entries) {
        cumulative += entry.value['net']!;
        cashFlowTrends[entry.key] = cumulative;
      }

      final data = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'duration': endDate.difference(startDate).inDays,
        'monthlyData': monthlyData,
        'cashFlowTrends': cashFlowTrends,
        'finalBalance': cumulative,
        'transactionCount': transactions.length,
      };

      return ReportModel(
        id: '',
        userId: userId,
        familyId: familyId,
        type: ReportType.cashFlow,
        name: 'Cash Flow Analysis',
        description: '${startDate.toLocal()} to ${endDate.toLocal()}',
        startDate: startDate,
        endDate: endDate,
        data: data,
        generatedAt: DateTime.now(),
        generatedBy: userId,
      );
    } catch (e) {
      throw Exception('Failed to generate cash flow: $e');
    }
  }

  // ============================================================
  // SAVE & RETRIEVE REPORTS
  // ============================================================

  Future<String> saveReport(ReportModel report) async {
    try {
      final data = report.toJson();
      data['generatedAt'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore.collection('reports').add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save report: $e');
    }
  }

  Future<List<ReportModel>> getSavedReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('generatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get saved reports: $e');
    }
  }

  Future<ReportModel?> getReportById(String id) async {
    try {
      final doc = await _firestore.collection('reports').doc(id).get();
      if (!doc.exists) return null;
      return ReportModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      await _firestore.collection('reports').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final doc = await _firestore.collection('reports').doc(id).get();
      if (!doc.exists) throw Exception('Report not found');
      
      final current = doc.data()?['isFavorite'] ?? false;
      await _firestore.collection('reports').doc(id).update({
        'isFavorite': !current,
      });
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _findBestMonth(Map<String, Map<String, double>> monthlyData) {
    if (monthlyData.isEmpty) return '';
    
    String bestMonth = '';
    double bestNet = double.negativeInfinity;
    
    for (var entry in monthlyData.entries) {
      final net = entry.value['net'] ?? 0.0;
      if (net > bestNet) {
        bestNet = net;
        bestMonth = entry.key;
      }
    }
    
    return bestMonth;
  }

  String _findWorstMonth(Map<String, Map<String, double>> monthlyData) {
    if (monthlyData.isEmpty) return '';
    
    String worstMonth = '';
    double worstNet = double.infinity;
    
    for (var entry in monthlyData.entries) {
      final net = entry.value['net'] ?? 0.0;
      if (net < worstNet) {
        worstNet = net;
        worstMonth = entry.key;
      }
    }
    
    return worstMonth;
  }
}
