import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../../models/transaction_model.dart' as tx;

class AdminFinancialLogsScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminFinancialLogsScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminFinancialLogsScreen> createState() => _AdminFinancialLogsScreenState();
}

class _AdminFinancialLogsScreenState extends State<AdminFinancialLogsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<tx.Transaction> _allTransactions = [];
  List<tx.Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _selectedType = 'all';
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactionsRealTime();
  }

  void _loadTransactionsRealTime() {
    setState(() {
      _isLoading = true;
    });

    _firestore
        .collectionGroup('transactions')
        .orderBy('date', descending: true)
        .limit(500)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _allTransactions = snapshot.docs
            .map((doc) => tx.Transaction.fromFirestore(doc.data()))
            .toList();
        _filteredTransactions = List.from(_allTransactions);
        _isLoading = false;
      });
    }, onError: (error) {
      debugPrint('Error loading transactions: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _filterTransactions() {
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        if (_selectedType != 'all' && tx.type != _selectedType) {
          return false;
        }
        
        if (_selectedPeriod != 'all') {
          final now = DateTime.now();
          final txDate = tx.date;
          if (_selectedPeriod == 'today') {
            return txDate.year == now.year && 
                   txDate.month == now.month && 
                   txDate.day == now.day;
          } else if (_selectedPeriod == 'week') {
            final weekAgo = now.subtract(const Duration(days: 7));
            return txDate.isAfter(weekAgo);
          } else if (_selectedPeriod == 'month') {
            final monthAgo = now.subtract(const Duration(days: 30));
            return txDate.isAfter(monthAgo);
          }
        }
        
        return true;
      }).toList();
    });
  }

  double _getTotalVolume() {
    return _filteredTransactions.fold(0.0, (double total, tx.Transaction transaction) => total + transaction.amount.abs());
  }

  double _getTotalInflow() {
    return _filteredTransactions
        .where((tx) => tx.amount > 0)
        .fold(0.0, (double total, tx.Transaction transaction) => total + transaction.amount);
  }

  double _getTotalOutflow() {
    return _filteredTransactions
        .where((tx) => tx.amount < 0)
        .fold(0.0, (double total, tx.Transaction transaction) => total + transaction.amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('financial_logs'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Real-time stream handles updates automatically
              setState(() {
                _isLoading = true;
              });
            },
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Volume',
                      '\$${_getTotalVolume().toStringAsFixed(2)}',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Inflow',
                      '\$${_getTotalInflow().toStringAsFixed(2)}',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Outflow',
                      '\$${_getTotalOutflow().toStringAsFixed(2)}',
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            
            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedType,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(value: 'admin_recharge', child: Text('Admin Recharge')),
                      DropdownMenuItem(value: 'admin_deduction', child: Text('Admin Deduction')),
                      DropdownMenuItem(value: 'purchase', child: Text('Purchase')),
                      DropdownMenuItem(value: 'gift', child: Text('Gift')),
                      DropdownMenuItem(value: 'agency_transfer', child: Text('Agency Transfer')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                      _filterTransactions();
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Time')),
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(value: 'week', child: Text('This Week')),
                      DropdownMenuItem(value: 'month', child: Text('This Month')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                      _filterTransactions();
                    },
                  ),
                ],
              ),
            ),
            
            // Transactions Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: const Border(
                                bottom: BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          
                          // Table Body
                          Expanded(
                            child: _filteredTransactions.isEmpty
                                ? Center(child: Text('No transactions found'))
                                : ListView.builder(
                                    itemCount: _filteredTransactions.length,
                                    itemBuilder: (context, index) {
                                      final tx = _filteredTransactions[index];
                                      final isPositive = tx.amount >= 0;
                                      
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                          border: const Border(
                                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(tx.date.toString().substring(0, 19)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(tx.type?.toUpperCase() ?? 'N/A'),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                tx.description ?? 'N/A',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '\$${tx.amount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: isPositive ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(tx.adminName ?? 'System'),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: _buildStatusChip(tx.status.name),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
