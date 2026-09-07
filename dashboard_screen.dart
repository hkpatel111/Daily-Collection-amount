import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/calculation_service.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/collection_dao.dart';
import '../models/loan.dart';
import '../widgets/stat_card.dart';
import 'customer_list_screen.dart';
import 'add_customer_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LoanDao _loanDao = LoanDao();
  final CollectionDao _collectionDao = CollectionDao();

  double _totalGiven = 0;
  double _totalCollected = 0;
  double _expectedProfit = 0;
  int _activeCount = 0;
  int _overdueCount = 0;
  int _completedCount = 0;
  int _defaultedCount = 0;
  double _todayTarget = 0;
  double _todayCollected = 0;
  int _todayPending = 0;
  List<Loan> _recentLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _totalGiven = await _loanDao.getTotalGiven();
      _totalCollected = await _loanDao.getTotalCollected();
      _expectedProfit = await _loanDao.getTotalExpectedProfit();
      _activeCount = await _loanDao.countByStatus(LoanStatus.active);
      _overdueCount = await _loanDao.countByStatus(LoanStatus.overdue);
      _completedCount = await _loanDao.countByStatus(LoanStatus.completed);
      _defaultedCount = await _loanDao.countByStatus(LoanStatus.defaulted);

      final today = CalculationService.today();
      final todayEntries = await _loanDao.getActiveLoans();
      _recentLoans = todayEntries.take(5).toList();

      // Today's collection target
      final todaySchedule = await _loanDao.getActiveLoans();
      _todayTarget = 0;
      _todayPending = 0;
      for (final loan in todaySchedule) {
        final totalCollected = await _collectionDao.getTotalCollectedByLoan(loan.id!);
        if (totalCollected < loan.returnAmount) {
          _todayTarget += loan.dailyInstallment;
          _todayPending++;
        }
      }
      _todayCollected = await _collectionDao.getTotalCollectedByDate(today);
    } catch (e) {
      // Ignore on first load when DB is empty
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.padding),
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      StatCard(
                        label: 'Total Given',
                        value: CalculationService.formatCurrency(_totalGiven),
                        color: AppColors.primary,
                        icon: Icons.account_balance_wallet,
                      ),
                      StatCard(
                        label: 'Total Collected',
                        value: CalculationService.formatCurrency(_totalCollected),
                        color: AppColors.success,
                        icon: Icons.savings,
                      ),
                      StatCard(
                        label: 'Expected Profit',
                        value: CalculationService.formatCurrency(_expectedProfit),
                        color: AppColors.completed,
                        icon: Icons.trending_up,
                      ),
                      StatCard(
                        label: 'Overdue Amount',
                        value: CalculationService.formatCurrency(
                            _totalGiven + _expectedProfit - _totalCollected > 0
                                ? 0
                                : 0),
                        color: AppColors.overdue,
                        icon: Icons.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.today, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text("Today's Collection",
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTodayStat('Target',
                                  CalculationService.formatCurrency(_todayTarget)),
                              _buildTodayStat('Collected',
                                  CalculationService.formatCurrency(_todayCollected)),
                              _buildTodayStat(
                                  'Pending', '$_todayPending loans'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _todayTarget > 0
                                ? (_todayCollected / _todayTarget).clamp(0.0, 1.0)
                                : 0,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusChip('Active', _activeCount, AppColors.active),
                      _buildStatusChip('Overdue', _overdueCount, AppColors.overdue),
                      _buildStatusChip('Done', _completedCount, AppColors.completed),
                      _buildStatusChip('Default', _defaultedCount, AppColors.defaulted),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Recent Active Loans',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CustomerListScreen())),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_recentLoans.isEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_add, color: AppColors.primary),
                        title: const Text('No active loans yet'),
                        subtitle: const Text('Add a customer to get started'),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AddCustomerScreen())),
                      ),
                    )
                  else
                    ..._recentLoans.map((loan) => _buildRecentLoanTile(loan)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildTodayStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildRecentLoanTile(Loan loan) {
    return Card(
      child: FutureBuilder<double>(
        future: _collectionDao.getTotalCollectedByLoan(loan.id!),
        builder: (context, snapshot) {
          final collected = snapshot.data ?? 0;
          return ListTile(
            title: Text('Loan #${loan.id}'),
            subtitle: Text(
              '${CalculationService.formatCurrency(collected)} / ${CalculationService.formatCurrency(loan.returnAmount)}',
            ),
            trailing: Text('${loan.totalDays} days'),
            onTap: () => Navigator.pushNamed(context, '/loan_detail', arguments: loan.id),
          );
        },
      ),
    );
  }
}
