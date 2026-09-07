import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/loan.dart';
import '../models/schedule_entry.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/schedule_dao.dart';
import '../database/dao/collection_dao.dart';
import '../services/calculation_service.dart';
import 'loan_detail_screen.dart';

class DailyCollectionScreen extends StatefulWidget {
  const DailyCollectionScreen({super.key});

  @override
  State<DailyCollectionScreen> createState() => _DailyCollectionScreenState();
}

class _DailyCollectionScreenState extends State<DailyCollectionScreen> {
  final LoanDao _loanDao = LoanDao();
  final ScheduleDao _scheduleDao = ScheduleDao();
  final CollectionDao _collectionDao = CollectionDao();
  List<_LoanCollectionItem> _items = [];
  bool _isLoading = true;
  double _todayTarget = 0;
  double _todayCollected = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final today = CalculationService.today();
    final activeLoans = await _loanDao.getActiveLoans();
    _items = [];
    _todayTarget = 0;
    _todayCollected = 0;

    for (final loan in activeLoans) {
      final entry = await _scheduleDao.getByLoanIdAndDate(loan.id!, today);
      if (entry != null && entry.status == ScheduleEntryStatus.pending && !entry.isHoliday) {
        _items.add(_LoanCollectionItem(loan: loan, scheduleEntry: entry));
        _todayTarget += entry.expectedAmount;
      }
    }

    _todayCollected = await _collectionDao.getTotalCollectedByDate(today);
    setState(() => _isLoading = false);
  }

  Future<void> _quickCollect(_LoanCollectionItem item, double amount) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: item.loan.id!)),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Today's Collections - ${CalculationService.formatDate(CalculationService.today())}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.padding),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Target', CalculationService.formatCurrency(_todayTarget)),
                          _buildStat('Collected', CalculationService.formatCurrency(_todayCollected)),
                          _buildStat('Pending', '${_items.length}'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text('No pending collections for today!',
                              style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: AppConstants.padding, vertical: 4),
                              child: ListTile(
                                title: Text('Loan #${item.loan.id} - Day ${item.scheduleEntry.dayNumber}'),
                                subtitle: Text(
                                  'Expected: ${CalculationService.formatCurrency(item.scheduleEntry.expectedAmount)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: AppColors.success),
                                      onPressed: () => _quickCollect(item, item.scheduleEntry.expectedAmount),
                                      tooltip: 'Record Collection',
                                    ),
                                  ],
                                ),
                                onTap: () => _quickCollect(item, item.scheduleEntry.expectedAmount),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _LoanCollectionItem {
  final Loan loan;
  final ScheduleEntry scheduleEntry;

  _LoanCollectionItem({required this.loan, required this.scheduleEntry});
}
