import '../models/loan.dart';
import '../models/schedule_entry.dart';
import '../models/collection_entry.dart';
import '../models/settings.dart';
import 'calculation_service.dart';
import '../database/dao/schedule_dao.dart';
import '../database/dao/collection_dao.dart';
import '../database/dao/loan_dao.dart';

class ScheduleService {
  final ScheduleDao _scheduleDao = ScheduleDao();
  final CollectionDao _collectionDao = CollectionDao();
  final LoanDao _loanDao = LoanDao();

  /// Generates daily schedule entries for a loan.
  /// If sundayHolidayEnabled is true, Sundays are marked as holidays
  /// and schedule extends by those days.
  Future<void> generateSchedule(Loan loan, AppSettings settings) async {
    final List<ScheduleEntry> entries = [];
    String currentDate = loan.startDate;
    int dayNumber = 1;

    while (dayNumber <= loan.totalDays) {
      bool isHoliday = false;

      if (settings.sundayHolidayEnabled && CalculationService.isSunday(currentDate)) {
        isHoliday = true;
        // Create a holiday entry (no collection expected)
        entries.add(ScheduleEntry(
          loanId: loan.id!,
          dayNumber: dayNumber,
          scheduledDate: currentDate,
          expectedAmount: 0,
          isHoliday: true,
          status: ScheduleEntryStatus.holiday,
          createdAt: CalculationService.now(),
        ));
        dayNumber++;
        currentDate = CalculationService.addDays(currentDate, 1);
        continue;
      }

      // Calculate expected amount
      double expectedAmount = loan.dailyInstallment;
      if (dayNumber == loan.totalDays) {
        expectedAmount = loan.lastDayAdjustedAmount;
      }

      entries.add(ScheduleEntry(
        loanId: loan.id!,
        dayNumber: dayNumber,
        scheduledDate: currentDate,
        expectedAmount: expectedAmount,
        isHoliday: isHoliday,
        status: ScheduleEntryStatus.pending,
        createdAt: CalculationService.now(),
      ));

      dayNumber++;
      currentDate = CalculationService.addDays(currentDate, 1);
    }

    await _scheduleDao.insertBatch(entries);
  }

  /// Record a collection entry for a schedule entry.
  /// Returns the CollectionEntry that was created.
  Future<CollectionEntry> recordCollection({
    required int loanId,
    required ScheduleEntry scheduleEntry,
    required double collectedAmount,
    String? note,
  }) async {
    final double expected = scheduleEntry.expectedAmount;
    final double shortfall = (expected - collectedAmount).clamp(0.0, double.infinity);

    ScheduleEntryStatus newStatus;
    bool isMissed = false;

    if (collectedAmount >= expected) {
      newStatus = ScheduleEntryStatus.paid;
    } else if (collectedAmount > 0) {
      newStatus = ScheduleEntryStatus.partial;
    } else {
      newStatus = ScheduleEntryStatus.missed;
      isMissed = true;
    }

    // Update schedule entry status
    scheduleEntry.status = newStatus;
    await _scheduleDao.update(scheduleEntry);

    // Create collection entry
    final entry = CollectionEntry(
      loanId: loanId,
      scheduleEntryId: scheduleEntry.id!,
      collectionDate: CalculationService.today(),
      expectedAmount: expected,
      collectedAmount: collectedAmount,
      shortfall: shortfall,
      isMissed: isMissed,
      overdueInterest: 0.0,
      note: note,
      createdAt: CalculationService.now(),
      updatedAt: CalculationService.now(),
    );

    final id = await _collectionDao.insert(entry);

    // Check if loan is fully collected
    await _checkLoanCompletion(loanId);

    return entry.copyWith(id: id);
  }

  /// Update overdue interest for all overdue entries in a loan.
  Future<void> updateOverdueInterest(int loanId, Loan loan, AppSettings settings) async {
    final overdueEntries = await _scheduleDao.getOverdueEntries(loanId);

    for (final entry in overdueEntries) {
      final collections = await _collectionDao.getByScheduleEntryId(entry.id!);
      if (collections.isEmpty) continue;

      final collection = collections.first;
      final double overduePrincipal = collection.shortfall > 0
          ? collection.shortfall
          : collection.expectedAmount;

      final int daysOverdue = CalculationService.daysBetween(
          entry.scheduledDate, CalculationService.today());

      final double interest = CalculationService.calculateOverdueInterest(
        overduePrincipal: overduePrincipal,
        dailyInterestRate: loan.dailyInterestRate,
        daysOverdue: daysOverdue,
        gracePeriodDays: settings.gracePeriodDays,
      );

      collection.overdueInterest = interest;
      collection.updatedAt = CalculationService.now();
      await _collectionDao.update(collection);
    }

    // Update loan status based on overdue
    await _updateLoanStatus(loanId, settings);
  }

  /// Update loan status: active -> overdue -> defaulted
  Future<void> _updateLoanStatus(int loanId, AppSettings settings) async {
    final loan = await _loanDao.getById(loanId);
    if (loan == null) return;
    if (loan.status == LoanStatus.completed ||
        loan.status == LoanStatus.preClosed ||
        loan.status == LoanStatus.cancelled) {
      return;
    }

    final overdueEntries = await _scheduleDao.getOverdueEntries(loanId);
    if (overdueEntries.isEmpty) {
      await _loanDao.updateStatus(loanId, LoanStatus.active);
      return;
    }

    // Find max overdue days
    int maxOverdueDays = 0;
    for (final entry in overdueEntries) {
      final int days = CalculationService.daysBetween(
          entry.scheduledDate, CalculationService.today());
      if (days > maxOverdueDays) maxOverdueDays = days;
    }

    if (maxOverdueDays > settings.defaultedThresholdDays) {
      await _loanDao.updateStatus(loanId, LoanStatus.defaulted);
    } else {
      await _loanDao.updateStatus(loanId, LoanStatus.overdue);
    }
  }

  /// Check if loan is fully collected and mark as completed.
  Future<void> _checkLoanCompletion(int loanId) async {
    final loan = await _loanDao.getById(loanId);
    if (loan == null) return;
    if (loan.status == LoanStatus.completed ||
        loan.status == LoanStatus.preClosed ||
        loan.status == LoanStatus.cancelled) {
      return;
    }

    final totalCollected = await _collectionDao.getTotalCollectedByLoan(loanId);
    if (totalCollected >= loan.returnAmount) {
      await _loanDao.updateStatus(loanId, LoanStatus.completed);
    }
  }

  /// Pre-close a loan: cancel all pending schedule entries and mark loan.
  Future<void> preCloseLoan(int loanId) async {
    await _scheduleDao.cancelPendingByLoan(loanId);
    await _loanDao.updateStatus(loanId, LoanStatus.preClosed);
  }

  /// Cancel a loan (if entered wrongly).
  Future<void> cancelLoan(int loanId) async {
    await _scheduleDao.cancelPendingByLoan(loanId);
    await _loanDao.updateStatus(loanId, LoanStatus.cancelled);
  }

  /// Get schedule entry for today for a loan.
  Future<ScheduleEntry?> getTodayEntry(int loanId) async {
    final today = CalculationService.today();
    return await _scheduleDao.getByLoanIdAndDate(loanId, today);
  }
}
