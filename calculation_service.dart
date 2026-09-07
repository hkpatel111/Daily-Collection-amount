import '../models/loan.dart';

class CalculationResult {
  final int totalDays;
  final double profit;
  final double dailyInterestRate;
  final double lastDayAdjustedAmount;
  final String endDate;

  CalculationResult({
    required this.totalDays,
    required this.profit,
    required this.dailyInterestRate,
    required this.lastDayAdjustedAmount,
    required this.endDate,
  });
}

class BalanceInfo {
  final double totalCollected;
  final double remainingAmount;
  final int daysElapsed;
  final int daysRemaining;
  final double overdueAmount;
  final double totalOverdueInterest;

  BalanceInfo({
    required this.totalCollected,
    required this.remainingAmount,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.overdueAmount,
    required this.totalOverdueInterest,
  });
}

class CalculationService {
  /// Calculates loan parameters from inputs.
  /// totalDays = ceil(returnAmount / dailyInstallment)
  /// profit = returnAmount - principal
  /// dailyInterestRate = (profit / (principal * totalDays)) * 100
  /// lastDayAdjustedAmount handles non-exact division.
  static CalculationResult calculateLoan({
    required double principal,
    required double returnAmount,
    required double dailyInstallment,
    required String startDate,
  }) {
    final double profit = returnAmount - principal;

    // Calculate total days and last day adjustment
    final double exactDays = returnAmount / dailyInstallment;
    final int fullDays = exactDays.floor();
    final double remainder = returnAmount - (fullDays * dailyInstallment);

    int totalDays;
    double lastDayAdjustedAmount;

    if (remainder.abs() < 0.01) {
      // Exact division
      totalDays = fullDays;
      lastDayAdjustedAmount = dailyInstallment;
    } else {
      // Not exact: last day gets the remainder
      totalDays = fullDays + 1;
      lastDayAdjustedAmount = remainder;
    }

    // Daily interest rate as percentage
    double dailyInterestRate = 0.0;
    if (principal > 0 && totalDays > 0) {
      dailyInterestRate = (profit / (principal * totalDays)) * 100;
    }

    // Calculate end date
    final DateTime start = DateTime.parse(startDate);
    final DateTime end = start.add(Duration(days: totalDays - 1));
    final String endDate =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    return CalculationResult(
      totalDays: totalDays,
      profit: profit,
      dailyInterestRate: dailyInterestRate,
      lastDayAdjustedAmount: lastDayAdjustedAmount,
      endDate: endDate,
    );
  }

  /// Calculates simple interest on overdue amount.
  /// Simple Interest = P * (R / 100) * T
  /// P = overdue principal, R = daily interest rate %, T = days overdue (after grace)
  static double calculateOverdueInterest({
    required double overduePrincipal,
    required double dailyInterestRate,
    required int daysOverdue,
    required int gracePeriodDays,
  }) {
    final int effectiveDays = daysOverdue - gracePeriodDays;
    if (effectiveDays <= 0) return 0.0;
    return overduePrincipal * (dailyInterestRate / 100) * effectiveDays;
  }

  /// Calculate days between two dates (inclusive of start)
  static int daysBetween(String startDate, String endDate) {
    final DateTime start = DateTime.parse(startDate);
    final DateTime end = DateTime.parse(endDate);
    return end.difference(start).inDays;
  }

  /// Get today's date as ISO string (yyyy-MM-dd)
  static String today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get current timestamp as ISO string
  static String now() {
    return DateTime.now().toIso8601String();
  }

  /// Format currency in Indian format
  static String formatCurrency(double amount) {
    // Indian formatting: 1,00,000
    final bool isNegative = amount < 0;
    final String str = amount.abs().toStringAsFixed(2);
    final parts = str.split('.');
    final String intPart = parts[0];
    final String decPart = parts.length > 1 ? parts[1] : '00';

    // Indian comma formatting
    String formatted;
    if (intPart.length <= 3) {
      formatted = intPart;
    } else {
      final int lastThree = intPart.length - 3;
      final String last3 = intPart.substring(lastThree);
      String rest = intPart.substring(0, lastThree);
      final sb = StringBuffer();
      for (int i = 0; i < rest.length; i++) {
        if (i > 0 && (rest.length - i) % 2 == 0) {
          sb.write(',');
        }
        sb.write(rest[i]);
      }
      formatted = '${sb.toString()},$last3';
    }

    final result = '$formatted.$decPart';
    return isNegative ? '-\u20B9$result' : '\u20B9$result';
  }

  /// Check if a date is Sunday
  static bool isSunday(String dateStr) {
    final date = DateTime.parse(dateStr);
    return date.weekday == DateTime.sunday;
  }

  /// Add days to a date string and return new date string
  static String addDays(String dateStr, int days) {
    final date = DateTime.parse(dateStr).add(Duration(days: days));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get day name from date string
  static String dayName(String dateStr) {
    final date = DateTime.parse(dateStr);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Format date as dd/MM/yyyy
  static String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Calculate balance info for a loan
  static BalanceInfo calculateBalance({
    required Loan loan,
    required double totalCollected,
    required double totalShortfall,
    required double totalOverdueInterest,
  }) {
    final double remainingAmount = loan.returnAmount - totalCollected;
    final String today = CalculationService.today();
    final int daysElapsed = daysBetween(loan.startDate, today);
    int daysRemaining = loan.totalDays - daysElapsed;
    if (daysRemaining < 0) daysRemaining = 0;

    return BalanceInfo(
      totalCollected: totalCollected,
      remainingAmount: remainingAmount,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      overdueAmount: totalShortfall + totalOverdueInterest,
      totalOverdueInterest: totalOverdueInterest,
    );
  }
}
