enum ScheduleEntryStatus {
  pending,
  paid,
  partial,
  missed,
  holiday,
  cancelled;

  String get dbValue {
    switch (this) {
      case ScheduleEntryStatus.pending:
        return 'pending';
      case ScheduleEntryStatus.paid:
        return 'paid';
      case ScheduleEntryStatus.partial:
        return 'partial';
      case ScheduleEntryStatus.missed:
        return 'missed';
      case ScheduleEntryStatus.holiday:
        return 'holiday';
      case ScheduleEntryStatus.cancelled:
        return 'cancelled';
    }
  }

  static ScheduleEntryStatus fromDbValue(String value) {
    switch (value) {
      case 'pending':
        return ScheduleEntryStatus.pending;
      case 'paid':
        return ScheduleEntryStatus.paid;
      case 'partial':
        return ScheduleEntryStatus.partial;
      case 'missed':
        return ScheduleEntryStatus.missed;
      case 'holiday':
        return ScheduleEntryStatus.holiday;
      case 'cancelled':
        return ScheduleEntryStatus.cancelled;
      default:
        return ScheduleEntryStatus.pending;
    }
  }
}

class ScheduleEntry {
  final int? id;
  final int loanId;
  final int dayNumber;
  final String scheduledDate;
  final double expectedAmount;
  final bool isHoliday;
  ScheduleEntryStatus status;
  final String createdAt;

  ScheduleEntry({
    this.id,
    required this.loanId,
    required this.dayNumber,
    required this.scheduledDate,
    required this.expectedAmount,
    this.isHoliday = false,
    this.status = ScheduleEntryStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_id': loanId,
      'day_number': dayNumber,
      'scheduled_date': scheduledDate,
      'expected_amount': expectedAmount,
      'is_holiday': isHoliday ? 1 : 0,
      'status': status.dbValue,
      'created_at': createdAt,
    };
  }

  factory ScheduleEntry.fromMap(Map<String, dynamic> map) {
    return ScheduleEntry(
      id: map['id'] as int?,
      loanId: map['loan_id'] as int,
      dayNumber: map['day_number'] as int,
      scheduledDate: map['scheduled_date'] as String,
      expectedAmount: (map['expected_amount'] as num).toDouble(),
      isHoliday: (map['is_holiday'] as int) == 1,
      status: ScheduleEntryStatus.fromDbValue(map['status'] as String),
      createdAt: map['created_at'] as String,
    );
  }

  ScheduleEntry copyWith({
    int? id,
    int? loanId,
    int? dayNumber,
    String? scheduledDate,
    double? expectedAmount,
    bool? isHoliday,
    ScheduleEntryStatus? status,
    String? createdAt,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      dayNumber: dayNumber ?? this.dayNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      isHoliday: isHoliday ?? this.isHoliday,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
