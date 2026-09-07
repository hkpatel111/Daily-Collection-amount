import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/loan.dart';
import '../models/schedule_entry.dart';
import '../models/collection_entry.dart';
import '../models/settings.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/schedule_dao.dart';
import '../database/dao/collection_dao.dart';
import '../database/dao/settings_dao.dart';
import '../database/dao/customer_dao.dart';
import '../services/calculation_service.dart';
import '../services/schedule_service.dart';
import '../services/sms_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/schedule_entry_tile.dart';
import 'pre_close_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  final int loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final LoanDao _loanDao = LoanDao();
  final ScheduleDao _scheduleDao = ScheduleDao();
  final CollectionDao _collectionDao = CollectionDao();
  final SettingsDao _settingsDao = SettingsDao();
  final CustomerDao _customerDao = CustomerDao();
  final ScheduleService _scheduleService = ScheduleService();
  final SmsService _smsService = SmsService();

  Loan? _loan;
  String _customerName = '';
  String _customerMobile = '';
  List<ScheduleEntry> _schedule = [];
  List<CollectionEntry> _collections = [];
  AppSettings _settings = AppSettings();
  double _totalCollected = 0;
  double _totalShortfall = 0;
  double _totalOverdueInterest = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _loan = await _loanDao.getById(widget.loanId);
    if (_loan != null) {
      final customer = await _customerDao.getById(_loan!.customerId);
      _customerName = customer?.name ?? '';
      _customerMobile = customer?.mobile ?? '';
      _settings = await _settingsDao.getSettings();
      _schedule = await _scheduleDao.getByLoanId(widget.loanId, limit: 30);
      _collections = await _collectionDao.getByLoanId(widget.loanId);
      _totalCollected = await _collectionDao.getTotalCollectedByLoan(widget.loanId);
      _totalShortfall = await _collectionDao.getTotalShortfallByLoan(widget.loanId);
      _totalOverdueInterest = await _collectionDao.getTotalOverdueInterestByLoan(widget.loanId);

      // Update overdue interest
      if (_loan!.status == LoanStatus.active || _loan!.status == LoanStatus.overdue) {
        await _scheduleService.updateOverdueInterest(widget.loanId, _loan!, _settings);
        _loan = await _loanDao.getById(widget.loanId);
        _totalOverdueInterest = await _collectionDao.getTotalOverdueInterestByLoan(widget.loanId);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _recordCollection(ScheduleEntry entry, double amount) async {
    if (_loan == null) return;

    await _scheduleService.recordCollection(
      loanId: widget.loanId,
      scheduleEntry: entry,
      collectedAmount: amount,
    );

    // Send SMS if enabled
    if (_settings.smsEnabled && _settings.smsOnPayment && _customerMobile.isNotEmpty) {
      final newCollected = _totalCollected + amount;
      final remaining = _loan!.returnAmount - newCollected;
      final msg = _smsService.buildPaymentReceivedSms(
        customerName: _customerName,
        amount: amount,
        remaining: remaining,
        returnAmount: _loan!.returnAmount,
        day: entry.dayNumber,
        totalDays: _loan!.totalDays,
        ownerName: _settings.ownerName,
      );

      if (_settings.smsAutoSend) {
        await _smsService.sendSms(to: _customerMobile, body: msg);
      } else {
        _showSmsPreview(msg, _customerMobile);
      }
    }

    _loadData();
  }

  void _showSmsPreview(String message, String mobile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send SMS?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: +91 $mobile'),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _smsService.sendSms(to: mobile, body: message);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showCollectionDialog(ScheduleEntry entry) {
    final amountCtrl = TextEditingController(
      text: entry.expectedAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Day ${entry.dayNumber} Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Expected: ${CalculationService.formatCurrency(entry.expectedAmount)}'),
            Text('Date: ${CalculationService.formatDate(entry.scheduledDate)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount Received',
                border: OutlineInputBorder(),
                prefixText: '\u20B9 ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              Navigator.pop(ctx);
              _recordCollection(entry, amount);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  Future<void> _preCloseLoan() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PreCloseScreen(loanId: widget.loanId)),
    );
    if (result == true) {
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _cancelLoan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Loan'),
        content: const Text('This will cancel all pending schedule entries. '
            'This action cannot be undone. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel Loan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _scheduleService.cancelLoan(widget.loanId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan')),
        body: const Center(child: Text('Loan not found')),
      );
    }

    final remaining = _loan!.returnAmount - _totalCollected;
    final daysElapsed = CalculationService.daysBetween(_loan!.startDate, CalculationService.today());
    int daysRemaining = _loan!.totalDays - daysElapsed;
    if (daysRemaining < 0) daysRemaining = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Loan: $_customerName'),
        actions: [
          PopupMenuButton(
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'preclose', child: Text('Pre-Close Loan')),
              const PopupMenuItem(value: 'cancel', child: Text('Cancel Loan')),
            ],
            onSelected: (value) {
              if (value == 'preclose') _preCloseLoan();
              if (value == 'cancel') _cancelLoan();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padding),
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${CalculationService.formatCurrency(_loan!.principal)} \u2192 ${CalculationService.formatCurrency(_loan!.returnAmount)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('${_loan!.totalDays} Days | ${CalculationService.formatCurrency(_loan!.dailyInstallment)}/day'),
                  const SizedBox(height: 4),
                  Text('Start: ${CalculationService.formatDate(_loan!.startDate)} | End: ${CalculationService.formatDate(_loan!.endDate)}'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              StatCard(label: 'Collected', value: CalculationService.formatCurrency(_totalCollected), color: AppColors.success, icon: Icons.check_circle),
              StatCard(label: 'Remaining', value: CalculationService.formatCurrency(remaining), color: AppColors.warning, icon: Icons.pending),
              StatCard(label: 'Days', value: '$daysElapsed/${_loan!.totalDays}', color: AppColors.primary, icon: Icons.calendar_today),
              StatCard(label: 'Overdue', value: CalculationService.formatCurrency(_totalShortfall + _totalOverdueInterest), color: AppColors.overdue, icon: Icons.warning),
            ],
          ),
          const SizedBox(height: 16),
          Text('DAILY SCHEDULE',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ..._schedule.map((entry) {
            final entryCollections = _collections
                .where((c) => c.scheduleEntryId == entry.id)
                .toList();
            return ScheduleEntryTile(
              entry: entry,
              collections: entryCollections,
              onTap: entry.status == ScheduleEntryStatus.pending && !entry.isHoliday
                  ? () => _showCollectionDialog(entry)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
