import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer.dart';
import '../models/loan.dart';
import '../database/dao/customer_dao.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/collection_dao.dart';
import '../services/calculation_service.dart';
import '../widgets/stat_card.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerDao _customerDao = CustomerDao();
  final LoanDao _loanDao = LoanDao();
  final CollectionDao _collectionDao = CollectionDao();
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    _customers = await _customerDao.getAll(activeOnly: !_showArchived);
    _filtered = _customers;
    setState(() => _isLoading = false);
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _customers;
      } else {
        _filtered = _customers
            .where((c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.mobile.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.list : Icons.archive),
            onPressed: () {
              _showArchived = !_showArchived;
              _loadCustomers();
            },
            tooltip: _showArchived ? 'Show Active' : 'Show Archived',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or mobile',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _showArchived
                              ? 'No archived customers'
                              : 'No customers yet. Tap + to add one.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final customer = _filtered[index];
                          return _buildCustomerTile(customer);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
          _loadCustomers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.padding, vertical: 4),
      child: FutureBuilder<Loan?>(
        future: _loanDao.getActiveLoanByCustomer(customer.id!),
        builder: (context, snapshot) {
          final activeLoan = snapshot.data;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                customer.name.isNotEmpty
                    ? customer.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(customer.name),
            subtitle: Text(
              customer.mobile +
                  (activeLoan != null
                      ? ' | Active: ${CalculationService.formatCurrency(activeLoan.principal)} \u2192 ${CalculationService.formatCurrency(activeLoan.returnAmount)}'
                      : ' | No active loan'),
            ),
            trailing: activeLoan != null
                ? const LoanStatusBadgeInline(status: LoanStatus.active)
                : null,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => CustomerDetailScreen(customerId: customer.id!)));
              _loadCustomers();
            },
          );
        },
      ),
    );
  }
}

// Small inline badge to avoid circular import
class LoanStatusBadgeInline extends StatelessWidget {
  final LoanStatus status;
  const LoanStatusBadgeInline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.active.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.label,
          style: const TextStyle(color: AppColors.active, fontSize: 11)),
    );
  }
}
