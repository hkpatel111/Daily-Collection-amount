import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'calculation_service.dart';
import '../database/dao/customer_dao.dart';
import '../database/dao/loan_dao.dart';
import '../database/dao/schedule_dao.dart';
import '../database/dao/collection_dao.dart';
import '../database/database_helper.dart';

class BackupResult {
  final bool success;
  final String? filePath;
  final String message;

  BackupResult({
    required this.success,
    this.filePath,
    required this.message,
  });
}

class BackupService {
  final CustomerDao _customerDao = CustomerDao();
  final LoanDao _loanDao = LoanDao();
  final ScheduleDao _scheduleDao = ScheduleDao();
  final CollectionDao _collectionDao = CollectionDao();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Export all data to a JSON file.
  /// Returns the file path on success.
  Future<BackupResult> exportData() async {
    try {
      final customers = await _customerDao.getAllRaw();
      final loans = await _loanDao.getAllRaw();
      final scheduleEntries = await _scheduleDao.getAllRaw();
      final collectionEntries = await _collectionDao.getAllRaw();

      final Map<String, dynamic> data = {
        'version': 1,
        'exported_at': CalculationService.now(),
        'customers': customers,
        'loans': loans,
        'schedule_entries': scheduleEntries,
        'collection_entries': collectionEntries,
      };

      final String jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final String fileName = 'backup_$timestamp.json';
      final String filePath = p.join(directory.path, fileName);

      final File file = File(filePath);
      await file.writeAsString(jsonStr);

      return BackupResult(
        success: true,
        filePath: filePath,
        message: 'Backup saved successfully',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Export failed: $e',
      );
    }
  }

  /// Import data from a JSON backup file.
  /// This replaces all existing data.
  Future<BackupResult> importData(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        return BackupResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      final String jsonStr = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonStr);

      // Clear existing data
      await _dbHelper.deleteAllData();

      // Import customers
      final customers = data['customers'] as List;
      for (final c in customers) {
        await _customerDao.insertRaw(c as Map<String, dynamic>);
      }

      // Import loans
      final loans = data['loans'] as List;
      for (final l in loans) {
        await _loanDao.insertRaw(l as Map<String, dynamic>);
      }

      // Import schedule entries
      final scheduleEntries = data['schedule_entries'] as List;
      for (final s in scheduleEntries) {
        await _scheduleDao.insertRaw(s as Map<String, dynamic>);
      }

      // Import collection entries
      final collectionEntries = data['collection_entries'] as List;
      for (final ce in collectionEntries) {
        await _collectionDao.insertRaw(ce as Map<String, dynamic>);
      }

      return BackupResult(
        success: true,
        message: 'Data imported successfully',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Import failed: $e',
      );
    }
  }

  /// Export collection data as CSV.
  Future<BackupResult> exportCsv() async {
    try {
      final loans = await _loanDao.getAllRaw();
      final collectionEntries = await _collectionDao.getAllRaw();

      final sb = StringBuffer();
      sb.writeln('Loan ID,Loan Date,Customer Name,Principal,Return Amount,Daily Installment,Total Days,Profit,Status');
      for (final loan in loans) {
        sb.writeln(
          '${loan['id']},${loan['start_date']},${loan['customer_id']},${loan['principal']},${loan['return_amount']},${loan['daily_installment']},${loan['total_days']},${loan['profit']},${loan['status']}',
        );
      }
      sb.writeln('');
      sb.writeln('Collection Date,Loan ID,Expected Amount,Collected Amount,Shortfall,Overdue Interest');
      for (final ce in collectionEntries) {
        sb.writeln(
          '${ce['collection_date']},${ce['loan_id']},${ce['expected_amount']},${ce['collected_amount']},${ce['shortfall']},${ce['overdue_interest']}',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final String fileName = 'export_$timestamp.csv';
      final String filePath = p.join(directory.path, fileName);

      final File file = File(filePath);
      await file.writeAsString(sb.toString());

      return BackupResult(
        success: true,
        filePath: filePath,
        message: 'CSV exported successfully',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'CSV export failed: $e',
      );
    }
  }
}
