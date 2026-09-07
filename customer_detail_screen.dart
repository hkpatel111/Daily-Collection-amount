import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer.dart';
import '../models/loan.dart';
import '../database/dao/customer_dao.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/collection_dao.dart';
import '../services/calculation_service.dart';
import '../widgets/stat_card.dart';
import 'loan_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final CustomerDao _customerDao = CustomerDao();
  final LoanDao _loanDao = LoanDao();
  final CollectionDao _collectionDao = CollectionDao();

  Customer? _customer;
  Loan? _activeLoan;
  List<Loan> _pastLoans = [];
  bool _isLoading = true;
  double _collected = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _customer = await _customerDao.getById(widget.customerId);
    _activeLoan = await _loanDao.getActiveLoanByCustomer(widget.customerId);
    final allLoans = await _loanDao.getByCustomer(widget.customerId);
    _pastLoans = allLoans
        .where((l) => l.status == LoanStatus.completed ||
            l.status == LoanStatus.preClosed ||
            l.status == LoanStatus.cancelled ||
            l.status == LoanStatus.defaulted)
        .toList();
    if (_activeLoan != null) {
      _collected = await _collectionDao.getTotalCollectedByLoan(_activeLoan!.id!);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _editCustomer() async {
    final nameCtrl = TextEditingController(text: _customer!.name);
    final mobileCtrl = TextEditingController(text: _customer!.mobile);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: mobileCtrl,
                decoration: const InputDecoration(labelText: 'Mobile', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _customerDao.update(_customer!.copyWith(
        name: nameCtrl.text.trim(),
        mobile: mobileCtrl.text.trim(),
      ));
      _loadData();
    }
  }

  Future<void> _archiveCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Customer'),
        content: Text('Archive ${_customer!.name}? This will hide them from the active list. '
            'All loan records will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Archive')),
        ],
      ),
    );

    if (confirmed == true) {
      await _customerDao.softDelete(widget.customerId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.name ?? 'Customer'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editCustomer),
          IconButton(icon: const Icon(Icons.archive), onPressed: _archiveCustomer),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.padding),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(_customer?.mobile ?? '',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Customer since: ${CalculationService.formatDate(_customer!.createdAt.substring(0, 10))}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_activeLoan != null)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => LoanDetailScreen(loanId: _activeLoan!.id!)));
                        _loadData();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ACTIVE LOAN',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text(
                              '${CalculationService.formatCurrency(_activeLoan!.principal)} \u2192 ${CalculationService.formatCurrency(_activeLoan!.returnAmount)} (${_activeLoan!.totalDays} days)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Started: ${CalculationService.formatDate(_activeLoan!.startDate)} | '
                              'Collected: ${CalculationService.formatCurrency(_collected)} / ${CalculationService.formatCurrency(_activeLoan!.returnAmount)}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                                Text(' Tap to open loan', style: TextStyle(color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      title: const Text('No active loan'),
                      subtitle: const Text('Create a new loan for this customer'),
                      leading: const Icon(Icons.add_circle, color: AppColors.primary),
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => AddCustomerScreen()));
                        _loadData();
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                if (_pastLoans.isNotEmpty) ...[
                  Text('LOAN HISTORY',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ..._pastLoans.map((loan) => _buildPastLoanTile(loan)),
                ],
              ],
            ),
    );
  }

  Widget _buildPastLoanTile(Loan loan) {
    return Card(
      child: ListTile(
        title: Text(
          '${CalculationService.formatCurrency(loan.principal)} \u2192 ${CalculationService.formatCurrency(loan.returnAmount)}',
        ),
        subtitle: Text(
          '${loan.status.label} | Profit: ${CalculationService.formatCurrency(loan.profit)}',
        ),
        trailing: Text('Loan #${loan.id}'),
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id!)));
          _loadData();
        },
      ),
    );
  }
}
