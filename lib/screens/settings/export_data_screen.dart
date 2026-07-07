// lib/screens/settings/export_data_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/common/loading_widget.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({Key? key}) : super(key: key);

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _isLoading = false;
  bool _isExporting = false;
  String? _exportPath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionProvider = context.watch<TransactionProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export Your Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Export your transactions and reports as CSV or PDF',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Export options
                  const Text(
                    'Export Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CSV Export
                  _buildExportOption(
                    icon: Icons.table_chart,
                    title: 'Export as CSV',
                    subtitle: 'Export all transactions as CSV file',
                    color: Colors.green,
                    isDark: isDark,
                    onTap: () => _exportData('csv'),
                  ),

                  const SizedBox(height: 12),

                  // PDF Export
                  _buildExportOption(
                    icon: Icons.picture_as_pdf,
                    title: 'Export as PDF',
                    subtitle: 'Export all transactions as PDF report',
                    color: Colors.red,
                    isDark: isDark,
                    onTap: () => _exportData('pdf'),
                  ),

                  const SizedBox(height: 12),

                  // Share
                  _buildExportOption(
                    icon: Icons.share,
                    title: 'Share Data',
                    subtitle: 'Share your data via email or other apps',
                    color: Colors.blue,
                    isDark: isDark,
                    onTap: _shareData,
                  ),

                  const SizedBox(height: 24),

                  // Export history
                  if (_exportPath != null) ...[
                    const Text(
                      'Export History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Export',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _exportPath!.split('/').last,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () {
                              // TODO: Open folder
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Info
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
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Exported files are saved in your device storage. You can share them via email or other apps.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String format) async {
    setState(() => _isExporting = true);

    try {
      final auth = context.read<AuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final currencyProvider = context.read<CurrencyProvider>();
      
      final transactions = transactionProvider.allTransactions;
      
      if (transactions.isEmpty) {
        CustomSnackBar.show(
          context,
          'No transactions to export',
          isError: true,
        );
        setState(() => _isExporting = false);
        return;
      }

      String? filePath;

      if (format == 'csv') {
        filePath = await ExportService.exportTransactionsToCsv(
          transactions,
          currencyCode: currencyProvider.currentCurrency,
        );
      } else if (format == 'pdf') {
        filePath = await ExportService.exportTransactionsToPdf(
          transactions,
          currencyCode: currencyProvider.currentCurrency,
          title: 'Transaction Report',
        );
      }

      if (filePath != null) {
        setState(() {
          _exportPath = filePath;
        });
        CustomSnackBar.show(
          context,
          'Data exported successfully! 📁',
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Failed to export: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareData() async {
    if (_exportPath == null) {
      CustomSnackBar.show(
        context,
        'Please export data first',
        isError: true,
      );
      return;
    }

    try {
      await ExportService.shareFile(_exportPath!);
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Failed to share: ${e.toString()}',
        isError: true,
      );
    }
  }
}
