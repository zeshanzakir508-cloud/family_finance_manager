// lib/screens/transactions/search_transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/transaction_model.dart';
import 'widgets/transaction_card.dart';

class SearchTransactionsScreen extends StatefulWidget {
  const SearchTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<SearchTransactionsScreen> createState() => _SearchTransactionsScreenState();
}

class _SearchTransactionsScreenState extends State<SearchTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<TransactionModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim();
      _performSearch();
    });
  }

  void _performSearch() {
    final transactionProvider = context.read<TransactionProvider>();
    final allTransactions = transactionProvider.allTransactions;

    if (_query.isEmpty) {
      _searchResults = [];
      return;
    }

    final queryLower = _query.toLowerCase();
    _searchResults = allTransactions.where((t) {
      return t.description?.toLowerCase().contains(queryLower) == true ||
          t.category?.toLowerCase().contains(queryLower) == true ||
          t.notes?.toLowerCase().contains(queryLower) == true ||
          t.type?.toLowerCase().contains(queryLower) == true ||
          t.amount?.toString().contains(queryLower) == true;
    }).toList();

    // Sort by relevance (description match first, then date)
    _searchResults.sort((a, b) {
      final aDesc = a.description?.toLowerCase().contains(queryLower) ?? false;
      final bDesc = b.description?.toLowerCase().contains(queryLower) ?? false;
      if (aDesc && !bDesc) return -1;
      if (!aDesc && bDesc) return 1;
      return (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by description, category, amount...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
        ),
      ),
      body: _buildContent(currencyProvider.currentCurrency),
    );
  }

  Widget _buildContent(String currency) {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Type something to search',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by description, category, amount, or notes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_query"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 4),
      itemBuilder: (context, index) {
        final transaction = _searchResults[index];
        return TransactionCard(
          transaction: transaction,
          currency: currency,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/transaction_detail',
              arguments: transaction.id,
            );
          },
        );
      },
    );
  }
}
