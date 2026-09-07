import 'package:flutter_test/flutter_test.dart';
import 'package:daily_collection_app/services/calculation_service.dart';

void main() {
  group('CalculationService', () {
    test('basic loan calculation', () {
      final result = CalculationService.calculateLoan(
        principal: 5000,
        returnAmount: 6000,
        dailyInstallment: 100,
        startDate: '2026-09-01',
      );
      expect(result.totalDays, 60);
      expect(result.profit, 1000);
      expect(result.dailyInterestRate, closeTo(0.333, 0.01));
      expect(result.lastDayAdjustedAmount, 100);
    });

    test('non-exact division adjusts last day', () {
      final result = CalculationService.calculateLoan(
        principal: 5000,
        returnAmount: 5500,
        dailyInstallment: 90,
        startDate: '2026-09-01',
      );
      expect(result.totalDays, 62);
      expect(result.lastDayAdjustedAmount, 10);
      expect(result.profit, 500);
    });

    test('overdue interest is simple', () {
      final interest = CalculationService.calculateOverdueInterest(
        overduePrincipal: 100,
        dailyInterestRate: 0.333,
        daysOverdue: 5,
        gracePeriodDays: 1,
      );
      expect(interest, closeTo(1.332, 0.01));
    });

    test('no interest during grace period', () {
      final interest = CalculationService.calculateOverdueInterest(
        overduePrincipal: 100,
        dailyInterestRate: 0.333,
        daysOverdue: 1,
        gracePeriodDays: 1,
      );
      expect(interest, 0.0);
    });

    test('date formatting', () {
      expect(CalculationService.formatDate('2026-09-07'), '07/09/2026');
    });
  });
}
