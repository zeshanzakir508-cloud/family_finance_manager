// lib/services/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../models/report_model.dart';
import '../services/currency_service.dart';

class ExportService {
  // ============================================================
  // CSV EXPORT
  // ============================================================

  static Future<String> exportTransactionsToCsv(
    List<TransactionModel> transactions, {
    String? currencyCode,
  }) async {
    try {
      final currency = currencyCode ?? await CurrencyService.getSelectedCurrency();
      final symbol = CurrencyService.getSymbol(currency);

      // Headers
      final headers = [
        'Date',
        'Type',
        'Category',
        'Description',
        'Amount ($currency)',
        'Notes',
        'Status',
      ];

      // Rows
      final rows = transactions.map((t) {
        return [
          t.date?.toLocal().toString().split(' ')[0] ?? '',
          t.typeDisplay,
          t.category ?? 'Other',
          t.description ?? '',
          '${symbol}${t.amount?.toStringAsFixed(2) ?? '0.00'}',
          t.notes ?? '',
          t.isDeleted == true ? 'Deleted' : 'Active',
        ];
      }).toList();

      // Combine headers and rows
      final csvData = [headers, ...rows];
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  static Future<String> exportReportToCsv(ReportModel report) async {
    try {
      final data = report.data;
      final rows = <List<String>>[];

      // Add report header
      rows.add(['Report: ${report.name}']);
      rows.add(['Generated: ${report.generatedAt.toLocal()}']);
      rows.add(['Period: ${report.startDate.toLocal()} - ${report.endDate.toLocal()}']);
      rows.add([]);

      if (report.type == ReportType.spendingBreakdown) {
        final categories = data['categories'] as Map<String, dynamic>?;
        if (categories != null) {
          rows.add(['Category', 'Amount']);
          for (var entry in categories.entries) {
            rows.add([entry.key, entry.value.toString()]);
          }
          rows.add([]);
          rows.add(['Total Spending', data['totalExpense'].toString()]);
          rows.add(['Transaction Count', data['transactionCount'].toString()]);
        }
      } else if (report.type == ReportType.incomeVsExpense) {
        rows.add(['Metric', 'Amount']);
        rows.add(['Total Income', data['totalIncome'].toString()]);
        rows.add(['Total Expense', data['totalExpense'].toString()]);
        rows.add(['Net Amount', data['netAmount'].toString()]);
        rows.add(['Income Count', data['incomeCount'].toString()]);
        rows.add(['Expense Count', data['expenseCount'].toString()]);
      }

      final csvString = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export report CSV: $e');
    }
  }

  // ============================================================
  // PDF EXPORT
  // ============================================================

  static Future<String> exportTransactionsToPdf(
    List<TransactionModel> transactions, {
    String? currencyCode,
    String? title,
  }) async {
    try {
      final currency = currencyCode ?? await CurrencyService.getSelectedCurrency();
      final symbol = CurrencyService.getSymbol(currency);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  title ?? 'Transaction Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${DateTime.now().toLocal()}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...transactions.map((t) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(t.date?.toLocal().toString().split(' ')[0] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            t.typeDisplay,
                            style: pw.TextStyle(
                              color: t.isIncome ? PdfColors.green : PdfColors.red,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(t.category ?? 'Other'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(t.description ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${symbol}${t.amount?.toStringAsFixed(2) ?? '0.00'}',
                            style: pw.TextStyle(
                              color: t.isIncome ? PdfColors.green : PdfColors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text('Total Income: '),
                        pw.Text(
                          '${symbol}${_calculateTotal(transactions, true).toStringAsFixed(2)}',
                          style: const pw.TextStyle(color: PdfColors.green),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Total Expense: '),
                        pw.Text(
                          '${symbol}${_calculateTotal(transactions, false).toStringAsFixed(2)}',
                          style: const pw.TextStyle(color: PdfColors.red),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Net: '),
                        pw.Text(
                          '${symbol}${_calculateNet(transactions).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            color: _calculateNet(transactions) >= 0
                                ? PdfColors.green
                                : PdfColors.red,
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Total Transactions: '),
                        pw.Text(transactions.length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  static Future<String> exportReportToPdf(ReportModel report) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  report.name,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                report.description ?? '',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated: ${report.generatedAt.toLocal()}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 20),
              _buildReportContent(report),
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      throw Exception('Failed to export report PDF: $e');
    }
  }

  // ============================================================
  // SHARE
  // ============================================================

  static Future<void> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out my finance report!',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  static Future<void> shareTransactionReport(
    List<TransactionModel> transactions, {
    String? currencyCode,
  }) async {
    try {
      final filePath = await exportTransactionsToCsv(transactions, currencyCode: currencyCode);
      await shareFile(filePath);
      
      // Clean up temp file after sharing
      await File(filePath).delete();
    } catch (e) {
      throw Exception('Failed to share report: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static double _calculateTotal(List<TransactionModel> transactions, bool income) {
    return transactions.fold<double>(0.0, (sum, t) {
      if (income && t.isIncome) return sum + (t.amount ?? 0.0);
      if (!income && t.isExpense) return sum + (t.amount ?? 0.0);
      return sum;
    });
  }

  static double _calculateNet(List<TransactionModel> transactions) {
    return _calculateTotal(transactions, true) - _calculateTotal(transactions, false);
  }

  static pw.Widget _buildReportContent(ReportModel report) {
    final data = report.data;

    switch (report.type) {
      case ReportType.spendingBreakdown:
        return _buildSpendingBreakdownContent(data);
      case ReportType.incomeVsExpense:
        return _buildIncomeExpenseContent(data);
      case ReportType.monthlyTrends:
        return _buildMonthlyTrendsContent(data);
      case ReportType.categoryWise:
        return _buildCategoryWiseContent(data);
      default:
        return pw.Text('Report content not available');
    }
  }

  static pw.Widget _buildSpendingBreakdownContent(Map<String, dynamic> data) {
    final categories = data['categories'] as Map<String, dynamic>?;
    final children = <pw.Widget>[];

    children.add(const pw.Text(
      'Spending Breakdown',
      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
    ));
    children.add(pw.SizedBox(height: 10));

    if (categories != null) {
      children.add(pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...categories.entries.map((entry) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.value.toString()),
                ),
              ],
            );
          }).toList(),
        ],
      ));
    }

    children.add(pw.SizedBox(height: 10));
    children.add(pw.Row(children: [
      pw.Text('Total: ${data['totalExpense']}'),
    ]));

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children);
  }

  static pw.Widget _buildIncomeExpenseContent(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Income vs Expense Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(children: [pw.Text('Total Income: '), pw.Text(data['totalIncome'].toString())]),
        pw.Row(children: [pw.Text('Total Expense: '), pw.Text(data['totalExpense'].toString())]),
        pw.Row(children: [
          pw.Text('Net: '),
          pw.Text(data['netAmount'].toString(),
              style: pw.TextStyle(
                  color: data['netAmount'] >= 0 ? PdfColors.green : PdfColors.red)),
        ]),
        pw.Row(children: [pw.Text('Income Count: '), pw.Text(data['incomeCount'].toString())]),
        pw.Row(children: [pw.Text('Expense Count: '), pw.Text(data['expenseCount'].toString())]),
      ],
    );
  }

  static pw.Widget _buildMonthlyTrendsContent(Map<String, dynamic> data) {
    final monthlyData = data['monthlyData'] as Map<String, dynamic>?;
    final children = <pw.Widget>[];

    children.add(pw.Text('Monthly Trends',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
    children.add(pw.SizedBox(height: 10));

    if (monthlyData != null) {
      children.add(pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Month', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Income', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Expense', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Net', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...monthlyData.entries.map((entry) {
            final values = entry.value as Map<String, dynamic>;
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(values['income'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(values['expense'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(values['net'].toString(),
                      style: pw.TextStyle(
                          color: values['net'] >= 0 ? PdfColors.green : PdfColors.red)),
                ),
              ],
            );
          }).toList(),
        ],
      ));
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children);
  }

  static pw.Widget _buildCategoryWiseContent(Map<String, dynamic> data) {
    final categories = data['categories'] as Map<String, dynamic>?;
    final children = <pw.Widget>[];

    children.add(pw.Text('Category-wise Spending',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
    children.add(pw.SizedBox(height: 10));

    if (categories != null) {
      children.add(pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Average', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...categories.entries.map((entry) {
            final values = entry.value as Map<String, dynamic>;
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(values['total'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(values['count'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(values['average'].toString()),
                ),
              ],
            );
          }).toList(),
        ],
      ));
    }

    children.add(pw.SizedBox(height: 10));
    children.add(pw.Row(children: [
      pw.Text('Total Spending: ${data['totalSpending']}'),
    ]));

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children);
  }
}
