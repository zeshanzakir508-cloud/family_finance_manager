// lib/providers/report_provider.dart
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();
  
  List<ReportModel> _savedReports = [];
  ReportModel? _currentReport;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<ReportModel> get savedReports => _savedReports;
  ReportModel? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  List<ReportModel> get favoriteReports {
    return _savedReports.where((r) => r.isFavorite).toList();
  }

  // ============================================================
  // GENERATE REPORTS
  // ============================================================

  Future<ReportModel?> generateSpendingBreakdown({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    _setGenerating(true);
    _clearError();

    try {
      final report = await _reportService.generateSpendingBreakdown(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        familyId: familyId,
      );
      _currentReport = report;
      _setGenerating(false);
      notifyListeners();
      return report;
    } catch (e) {
      _error = e.toString();
      _setGenerating(false);
      notifyListeners();
      return null;
    }
  }

  Future<ReportModel?> generateIncomeVsExpense({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    _setGenerating(true);
    _clearError();

    try {
      final report = await _reportService.generateIncomeVsExpense(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        familyId: familyId,
      );
      _currentReport = report;
      _setGenerating(false);
      notifyListeners();
      return report;
    } catch (e) {
      _error = e.toString();
      _setGenerating(false);
      notifyListeners();
      return null;
    }
  }

  Future<ReportModel?> generateMonthlyTrends({
    required String userId,
    required int year,
    String? familyId,
  }) async {
    _setGenerating(true);
    _clearError();

    try {
      final report = await _reportService.generateMonthlyTrends(
        userId: userId,
        year: year,
        familyId: familyId,
      );
      _currentReport = report;
      _setGenerating(false);
      notifyListeners();
      return report;
    } catch (e) {
      _error = e.toString();
      _setGenerating(false);
      notifyListeners();
      return null;
    }
  }

  Future<ReportModel?> generateCategoryWiseSpending({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    _setGenerating(true);
    _clearError();

    try {
      final report = await _reportService.generateCategoryWiseSpending(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        familyId: familyId,
      );
      _currentReport = report;
      _setGenerating(false);
      notifyListeners();
      return report;
    } catch (e) {
      _error = e.toString();
      _setGenerating(false);
      notifyListeners();
      return null;
    }
  }

  Future<ReportModel?> generateCashFlow({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? familyId,
  }) async {
    _setGenerating(true);
    _clearError();

    try {
      final report = await _reportService.generateCashFlow(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        familyId: familyId,
      );
      _currentReport = report;
      _setGenerating(false);
      notifyListeners();
      return report;
    } catch (e) {
      _error = e.toString();
      _setGenerating(false);
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // SAVE & MANAGE REPORTS
  // ============================================================

  Future<String?> saveReport(ReportModel report) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _reportService.saveReport(report);
      final savedReport = report.copyWith(id: id);
      _savedReports.insert(0, savedReport);
      _setLoading(false);
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  Future<void> loadSavedReports(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _savedReports = await _reportService.getSavedReports(userId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> deleteReport(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _reportService.deleteReport(id);
      _savedReports.removeWhere((r) => r.id == id);
      if (_currentReport?.id == id) {
        _currentReport = null;
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      await _reportService.toggleFavorite(id);
      
      final index = _savedReports.indexWhere((r) => r.id == id);
      if (index != -1) {
        _savedReports[index] = _savedReports[index].copyWith(
          isFavorite: !_savedReports[index].isFavorite,
        );
        notifyListeners();
      }
      
      if (_currentReport?.id == id) {
        _currentReport = _currentReport?.copyWith(
          isFavorite: !(_currentReport?.isFavorite ?? false),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // ============================================================
  // SET CURRENT
  // ============================================================

  void setCurrentReport(ReportModel report) {
    _currentReport = report;
    notifyListeners();
  }

  void setCurrentReportById(String id) {
    final report = _savedReports.firstWhere((r) => r.id == id);
    if (report != null) {
      _currentReport = report;
      notifyListeners();
    }
  }

  void clearCurrentReport() {
    _currentReport = null;
    notifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<ReportModel> getReportsByType(ReportType type) {
    return _savedReports.where((r) => r.type == type).toList();
  }

  List<ReportModel> getReportsByDateRange(DateTime start, DateTime end) {
    return _savedReports.where((r) {
      return r.startDate.isAfter(start) && r.endDate.isBefore(end);
    }).toList();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGenerating(bool generating) {
    _isGenerating = generating;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
