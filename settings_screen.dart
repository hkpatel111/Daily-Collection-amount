import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/settings.dart';
import '../database/dao/settings_dao.dart';
import '../services/backup_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsDao _settingsDao = SettingsDao();
  final BackupService _backupService = BackupService();
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await _settingsDao.getSettings();
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    await _settingsDao.updateSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    final result = await _backupService.exportData();
    setState(() => _isExporting = false);

    if (result.success && result.filePath != null) {
      await Share.shareXFiles(
        [XFile(result.filePath!)],
        subject: 'Daily Collection Backup',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text('This will replace ALL existing data. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
          ],
        ),
      );

      if (confirmed == true) {
        final importResult = await _backupService.importData(filePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(importResult.message)),
          );
        }
      }
    }
  }

  Future<void> _exportCsv() async {
    final result = await _backupService.exportCsv();
    if (result.success && result.filePath != null) {
      await Share.shareXFiles(
        [XFile(result.filePath!)],
        subject: 'Daily Collection CSV Export',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padding),
        children: [
          _sectionTitle('OWNER'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Your Name (shown in SMS)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _settings = _settings.copyWith(ownerName: v),
                controller: TextEditingController(text: _settings.ownerName),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('COLLECTION RULES'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Grace Period'),
                  subtitle: const Text('Days before overdue interest starts'),
                  trailing: SizedBox(
                    width: 60,
                    child: TextField(
                      decoration: const InputDecoration(border: InputBorder.none),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: _settings.gracePeriodDays.toString()),
                      onChanged: (v) {
                        final days = int.tryParse(v);
                        if (days != null) {
                          _settings = _settings.copyWith(gracePeriodDays: days);
                        }
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Defaulted Threshold'),
                  subtitle: const Text('Days overdue before loan is marked defaulted'),
                  trailing: SizedBox(
                    width: 60,
                    child: TextField(
                      decoration: const InputDecoration(border: InputBorder.none),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: _settings.defaultedThresholdDays.toString()),
                      onChanged: (v) {
                        final days = int.tryParse(v);
                        if (days != null) {
                          _settings = _settings.copyWith(defaultedThresholdDays: days);
                        }
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Skip Sundays'),
                  subtitle: const Text('No collection on Sundays, schedule extends'),
                  value: _settings.sundayHolidayEnabled,
                  onChanged: (v) => setState(() =>
                      _settings = _settings.copyWith(sundayHolidayEnabled: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('SMS'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('SMS Enabled'),
                  subtitle: const Text('Master switch for all SMS'),
                  value: _settings.smsEnabled,
                  onChanged: (v) => setState(() => _settings = _settings.copyWith(smsEnabled: v)),
                ),
                if (_settings.smsEnabled) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Payment Confirmation'),
                    value: _settings.smsOnPayment,
                    onChanged: (v) => setState(() => _settings = _settings.copyWith(smsOnPayment: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Missed Payment Reminder'),
                    value: _settings.smsOnMissed,
                    onChanged: (v) => setState(() => _settings = _settings.copyWith(smsOnMissed: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Loan Completion'),
                    value: _settings.smsOnCompletion,
                    onChanged: (v) => setState(() => _settings = _settings.copyWith(smsOnCompletion: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Pre-Closure'),
                    value: _settings.smsOnPreclosure,
                    onChanged: (v) => setState(() => _settings = _settings.copyWith(smsOnPreclosure: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto-Send (no confirmation prompt)'),
                    subtitle: const Text('If off, you will be asked before each SMS'),
                    value: _settings.smsAutoSend,
                    onChanged: (v) => setState(() => _settings = _settings.copyWith(smsAutoSend: v)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('DATA & BACKUP'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: _isExporting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.backup, color: AppColors.primary),
                  title: const Text('Export Data (Backup)'),
                  subtitle: const Text('Save all data as JSON file'),
                  onTap: _isExporting ? null : _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppColors.primary),
                  title: const Text('Import Data (Restore)'),
                  subtitle: const Text('Restore from backup file'),
                  onTap: _importData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart, color: AppColors.success),
                  title: const Text('Export as CSV'),
                  subtitle: const Text('Export loans and collections as CSV'),
                  onTap: _exportCsv,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('ABOUT'),
          Card(
            child: const ListTile(
              leading: Icon(Icons.info, color: AppColors.textSecondary),
              title: Text('Daily Collection App'),
              subtitle: Text('Version 1.0.0'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
