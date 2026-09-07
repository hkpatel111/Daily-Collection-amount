import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/schedule_entry.dart';
import '../models/collection_entry.dart';
import '../services/calculation_service.dart';

class ScheduleEntryTile extends StatelessWidget {
  final ScheduleEntry entry;
  final List<CollectionEntry> collections;
  final VoidCallback? onTap;

  const ScheduleEntryTile({
    super.key,
    required this.entry,
    this.collections = const [],
    this.onTap,
  });

  Color get _statusColor {
    switch (entry.status) {
      case ScheduleEntryStatus.paid:
        return AppColors.success;
      case ScheduleEntryStatus.partial:
        return AppColors.warning;
      case ScheduleEntryStatus.missed:
        return AppColors.error;
      case ScheduleEntryStatus.holiday:
        return AppColors.cancelled;
      case ScheduleEntryStatus.cancelled:
        return AppColors.cancelled;
      case ScheduleEntryStatus.pending:
        return AppColors.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (entry.status) {
      case ScheduleEntryStatus.paid:
        return Icons.check_circle;
      case ScheduleEntryStatus.partial:
        return Icons.warning;
      case ScheduleEntryStatus.missed:
        return Icons.cancel;
      case ScheduleEntryStatus.holiday:
        return Icons.weekend;
      case ScheduleEntryStatus.cancelled:
        return Icons.block;
      case ScheduleEntryStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCollected = collections.fold<double>(
        0, (sum, c) => sum + c.collectedAmount);

    return ListTile(
      onTap: onTap,
      leading: Icon(_statusIcon, color: _statusColor, size: 28),
      title: Text(
        'Day ${entry.dayNumber} - ${CalculationService.formatDate(entry.scheduledDate)}'
        '${CalculationService.isSunday(entry.scheduledDate) ? " (Sun)" : ""}',
        style: TextStyle(
          fontWeight: entry.status == ScheduleEntryStatus.pending
              ? FontWeight.normal
              : FontWeight.w500,
        ),
      ),
      subtitle: entry.isHoliday
          ? Text('Holiday', style: TextStyle(color: _statusColor))
          : entry.status == ScheduleEntryStatus.partial
              ? Text(
                  'Expected: ${CalculationService.formatCurrency(entry.expectedAmount)} | '
                  'Collected: ${CalculationService.formatCurrency(totalCollected)}',
                  style: TextStyle(color: _statusColor),
                )
              : Text(
                  CalculationService.formatCurrency(entry.expectedAmount),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
      trailing: entry.status == ScheduleEntryStatus.pending
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null,
      dense: true,
    );
  }
}
