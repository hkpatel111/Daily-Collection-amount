enum LoanStatus {
  active,
  overdue,
  preClosed,
  completed,
  defaulted,
  cancelled;

  String get label {
    switch (this) {
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.overdue:
        return 'Overdue';
      case LoanStatus.preClosed:
        return 'Pre-Closed';
      case LoanStatus.completed:
        return 'Completed';
      case LoanStatus.defaulted:
        return 'Defaulted';
      case LoanStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get dbValue {
    switch (this) {
      case LoanStatus.active:
        return 'active';
      case LoanStatus.overdue:
        return 'overdue';
      case LoanStatus.preClosed:
        return 'pre_closed';
      case LoanStatus.completed:
        return 'completed';
      case LoanStatus.defaulted:
        return 'defaulted';
      case LoanStatus.cancelled:
        return 'cancelled';
    }
  }

  static LoanStatus fromDbValue(String value) {
    switch (value) {
      case 'active':
        return LoanStatus.active;
      case 'overdue':
        return LoanStatus.overdue;
      case 'pre_closed':
        return LoanStatus.preClosed;
      case 'completed':
        return LoanStatus.completed;
      case 'defaulted':
        return LoanStatus.defaulted;
      case 'cancelled':
        return LoanStatus.cancelled;
      default:
        return LoanStatus.active;
    }
  }
}

class Loan {
  final int? id;
  final int customerId;
  final double principal;
  final double returnAmount;
  final double dailyInstallment;
  final int totalDays;
  final double profit;
  final double dailyInterestRate;
  final String startDate;
  final String endDate;
  LoanStatus status;
  final double lastDayAdjustedAmount;
  final String createdAt;

  Loan({
    this.id,
    required this.customerId,
    required this.principal,
    required this.returnAmount,
    required this.dailyInstallment,
    required this.totalDays,
    required this.profit,
    required this.dailyInterestRate,
    required this.startDate,
    required this.endDate,
    this.status = LoanStatus.active,
    required this.lastDayAdjustedAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'principal': principal,
      'return_amount': returnAmount,
      'daily_installment': dailyInstallment,
      'total_days': totalDays,
      'profit': profit,
      'daily_interest_rate': dailyInterestRate,
      'start_date': startDate,
      'end_date': endDate,
      'status': status.dbValue,
      'last_day_adjusted_amount': lastDayAdjustedAmount,
      'created_at': createdAt,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      principal: (map['principal'] as num).toDouble(),
      returnAmount: (map['return_amount'] as num).toDouble(),
      dailyInstallment: (map['daily_installment'] as num).toDouble(),
      totalDays: map['total_days'] as int,
      profit: (map['profit'] as num).toDouble(),
      dailyInterestRate: (map['daily_interest_rate'] as num).toDouble(),
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      status: LoanStatus.fromDbValue(map['status'] as String),
      lastDayAdjustedAmount: (map['last_day_adjusted_amount'] as num).toDouble(),
      createdAt: map['created_at'] as String,
    );
  }

  Loan copyWith({
    int? id,
    int? customerId,
    double? principal,
    double? returnAmount,
    double? dailyInstallment,
    int? totalDays,
    double? profit,
    double? dailyInterestRate,
    String? startDate,
    String? endDate,
    LoanStatus? status,
    double? lastDayAdjustedAmount,
    String? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      principal: principal ?? this.principal,
      returnAmount: returnAmount ?? this.returnAmount,
      dailyInstallment: dailyInstallment ?? this.dailyInstallment,
      totalDays: totalDays ?? this.totalDays,
      profit: profit ?? this.profit,
      dailyInterestRate: dailyInterestRate ?? this.dailyInterestRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      lastDayAdjustedAmount: lastDayAdjustedAmount ?? this.lastDayAdjustedAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
