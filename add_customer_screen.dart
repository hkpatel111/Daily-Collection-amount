import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../models/customer.dart';
import '../models/loan.dart';
import '../models/settings.dart';
import '../database/dao/customer_dao.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/settings_dao.dart';
import '../services/calculation_service.dart';
import '../services/schedule_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _principalController = TextEditingController();
  final _returnController = TextEditingController();
  final _installmentController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final CustomerDao _customerDao = CustomerDao();
  final LoanDao _loanDao = LoanDao();
  final SettingsDao _settingsDao = SettingsDao();
  final ScheduleService _scheduleService = ScheduleService();

  // Auto-calc preview
  int _previewDays = 0;
  double _previewProfit = 0;
  double _previewRate = 0;
  String _previewEndDate = '';

  void _updatePreview() {
    final principal = double.tryParse(_principalController.text) ?? 0;
    final returnAmount = double.tryParse(_returnController.text) ?? 0;
    final installment = double.tryParse(_installmentController.text) ?? 0;

    if (principal > 0 && returnAmount > principal && installment > 0) {
      final result = CalculationService.calculateLoan(
        principal: principal,
        returnAmount: returnAmount,
        dailyInstallment: installment,
        startDate: _formatDate(_selectedDate),
      );
      setState(() {
        _previewDays = result.totalDays;
        _previewProfit = result.profit;
        _previewRate = result.dailyInterestRate;
        _previewEndDate = result.endDate;
      });
    } else {
      setState(() {
        _previewDays = 0;
        _previewProfit = 0;
        _previewRate = 0;
        _previewEndDate = '';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _updatePreview();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final principal = double.parse(_principalController.text);
      final returnAmount = double.parse(_returnController.text);
      final installment = double.parse(_installmentController.text);

      // Check if customer already has active loan (existing customer)
      // For new customer, this check is skipped
      final mobile = _mobileController.text;
      final existingCustomers = await _customerDao.search(mobile);
      if (existingCustomers.isNotEmpty) {
        final existing = existingCustomers.first;
        final hasActive = await _customerDao.hasActiveLoan(existing.id!);
        if (hasActive) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This customer already has an active loan!')),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
        // Use existing customer
        await _createLoan(existing.id!, principal, returnAmount, installment);
      } else {
        // Create new customer
        final customer = Customer(
          name: _nameController.text.trim(),
          mobile: mobile,
          createdAt: CalculationService.now(),
        );
        final customerId = await _customerDao.insert(customer);
        await _createLoan(customerId, principal, returnAmount, installment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer and loan created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _createLoan(
      int customerId, double principal, double returnAmount, double installment) async {
    final startDate = _formatDate(_selectedDate);
    final calcResult = CalculationService.calculateLoan(
      principal: principal,
      returnAmount: returnAmount,
      dailyInstallment: installment,
      startDate: startDate,
    );

    final settings = await _settingsDao.getSettings();

    final loan = Loan(
      customerId: customerId,
      principal: principal,
      returnAmount: returnAmount,
      dailyInstallment: installment,
      totalDays: calcResult.totalDays,
      profit: calcResult.profit,
      dailyInterestRate: calcResult.dailyInterestRate,
      startDate: startDate,
      endDate: calcResult.endDate,
      lastDayAdjustedAmount: calcResult.lastDayAdjustedAmount,
      createdAt: CalculationService.now(),
    );

    final loanId = await _loanDao.insert(loan);
    final savedLoan = await _loanDao.getById(loanId);
    if (savedLoan != null) {
      await _scheduleService.generateSchedule(savedLoan, settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer & Loan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.padding),
          children: [
            Text('CUSTOMER DETAILS',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Beneficiary Name *',
                border: OutlineInputBorder(),
              ),
              validator: Validators.validateName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                border: OutlineInputBorder(),
                prefixText: '+91 ',
                keyboardType: TextInputType.phone,
              ),
              validator: Validators.validateMobile,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 24),
            Text('LOAN DETAILS',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _principalController,
              decoration: const InputDecoration(
                labelText: 'Given Amount (Principal) *',
                border: OutlineInputBorder(),
                prefixText: '\u20B9 ',
              ),
              validator: (v) => Validators.validateAmount(v, label: 'Principal'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _returnController,
              decoration: const InputDecoration(
                labelText: 'Return Amount (Total) *',
                border: OutlineInputBorder(),
                prefixText: '\u20B9 ',
              ),
              validator: (v) {
                final principal = double.tryParse(_principalController.text) ?? 0;
                return Validators.validateReturnAmount(v, principal);
              },
              keyboardType: TextInputType.number,
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _installmentController,
              decoration: const InputDecoration(
                labelText: 'Daily Installment *',
                border: OutlineInputBorder(),
                prefixText: '\u20B9 ',
              ),
              validator: (v) {
                final returnAmt = double.tryParse(_returnController.text) ?? 0;
                return Validators.validateDailyInstallment(v, returnAmt);
              },
              keyboardType: TextInputType.number,
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(CalculationService.formatDate(_formatDate(_selectedDate))),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_previewDays > 0)
              Card(
                color: AppColors.primary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-Calculated',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _buildPreviewRow('Total Days', '$_previewDays days'),
                      _buildPreviewRow('Profit', CalculationService.formatCurrency(_previewProfit)),
                      _buildPreviewRow('Daily Interest Rate',
                          '${_previewRate.toStringAsFixed(3)}%/day'),
                      _buildPreviewRow('End Date', CalculationService.formatDate(_previewEndDate)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Loan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _principalController.dispose();
    _returnController.dispose();
    _installmentController.dispose();
    super.dispose();
  }
}
