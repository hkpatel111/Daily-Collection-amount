import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/loan.dart';
import '../models/settings.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/collection_dao.dart';
import '../database/dao/settings_dao.dart';
import '../database/dao/customer_dao.dart';
import '../services/calculation_service.dart';
import '../services/schedule_service.dart';
import '../services/sms_service.dart';

class PreCloseScreen extends StatefulWidget {
  final int loanId;

  const PreCloseScreen({super.key, required this.loanId});

  @override
  State<PreCloseScreen> createState() => _PreCloseScreenState();
}

class _PreCloseScreenState extends State<PreCloseScreen> {
  final LoanDao _loanDao = LoanDao();
  final CollectionDao _collectionDao = CollectionDao();
  final SettingsDao _settingsDao = SettingsDao();
  final CustomerDao _customerDao = CustomerDao();
  final ScheduleService _scheduleService = ScheduleService();
  final SmsService _smsService = SmsService();

  Loan? _loan;
  String _customerName = '';
  String _customerMobile = '';
  double _collected = 0;
  double _overdueInterest = 0;
  bool _sendSms = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loan = await _loanDao.getById(widget.loanId);
    if (_loan != null) {
      final customer = await _customerDao.getById(_loan!.customerId);
      _customerName = customer?.name ?? '';
      _customerMobile = customer?.mobile ?? '';
      _collected = await _collectionDao.getTotalCollectedByLoan(widget.loanId);
      _overdueInterest = await _collectionDao.getTotalOverdueInterestByLoan(widget.loanId);
      final settings = await _settingsDao.getSettings();
      _sendSms = settings.smsEnabled && settings.smsOnPreclosure;
    }
    setState(() {});
  }

  Future<void> _confirmPreClose() async {
    if (_loan == null) return;
    setState(() => _isProcessing = true);

    await _scheduleService.preCloseLoan(widget.loanId);

    // Send SMS if enabled
    if (_sendSms && _customerMobile.isNotEmpty) {
      final remaining = _loan!.returnAmount - _collected;
      final payable = remaining + _overdueInterest;
      final settings = await _settingsDao.getSettings();
      final msg = _smsService.buildPreClosureSms(
        customerName: _customerName,
        payable: payable,
        ownerName: settings.ownerName,
      );
      await _smsService.sendSms(to: _customerMobile, body: msg);
    }

    setState(() => _isProcessing = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pre-Close Loan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final remaining = _loan!.returnAmount - _collected;
    final payable = remaining + _overdueInterest;

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Close Loan')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padding),
        children: [
          Card(
            color: AppColors.warning.withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('You are about to pre-close this loan. '
                        'All remaining schedule entries will be cancelled.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_customerName - Loan #${_loan!.id}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildRow('Principal', CalculationService.formatCurrency(_loan!.principal)),
                  _buildRow('Return Amount', CalculationService.formatCurrency(_loan!.returnAmount)),
                  _buildRow('Collected So Far', CalculationService.formatCurrency(_collected)),
                  _buildRow('Remaining', CalculationService.formatCurrency(remaining)),
                  _buildRow('Overdue Interest', CalculationService.formatCurrency(_overdueInterest)),
                  const Divider(),
                  _buildRow('TOTAL PAYABLE', CalculationService.formatCurrency(payable), isBold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _sendSms,
            onChanged: (v) => setState(() => _sendSms = v ?? false),
            title: const Text('Send SMS to customer'),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirmPreClose,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Pre-Close'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          )),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          )),
        ],
      ),
    );
  }
}
