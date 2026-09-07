
import 'package:telephony/telephony.dart';

class SmsResult {
  final bool success;
  final String message;

  SmsResult({required this.success, required this.message});
}

class SmsService {
  final Telephony _telephony = Telephony.instance;

  /// Check if SMS permissions are granted.
  Future<bool> hasPermission() async {
    final status = await _telephony.requestSmsPermissions(
      sendSms: true,
    );
    return status ?? false;
  }

  /// Send an SMS from the device SIM.
  /// Returns SmsResult with success status and message.
  Future<SmsResult> sendSms({
    required String to,
    required String body,
  }) async {
    try {
      await _telephony.sendSms(
        to: to,
        message: body,
        isMultipart: true,
      );
      return SmsResult(success: true, message: 'SMS sent successfully');
    } catch (e) {
      return SmsResult(success: false, message: 'Failed to send SMS: $e');
    }
  }

  /// Build SMS message for payment received.
  String buildPaymentReceivedSms({
    required String customerName,
    required double amount,
    required double remaining,
    required double returnAmount,
    required int day,
    required int totalDays,
    required String ownerName,
  }) {
    final amt = _formatAmount(amount);
    final rem = _formatAmount(remaining);
    final ret = _formatAmount(returnAmount);
    final owner = ownerName.isNotEmpty ? ' - $ownerName' : '';
    return 'Payment of $amt received from $customerName. '
        'Remaining: $rem/$ret. Day $day/$totalDays.$owner';
  }

  /// Build SMS message for missed payment reminder.
  String buildMissedPaymentSms({
    required String customerName,
    required double amount,
    required int day,
    required String ownerName,
  }) {
    final amt = _formatAmount(amount);
    final owner = ownerName.isNotEmpty ? ' - $ownerName' : '';
    return 'Reminder: $amt pending for $customerName\'s loan (Day $day). '
        'Please pay at the earliest.$owner';
  }

  /// Build SMS message for loan completion.
  String buildLoanCompletedSms({
    required String customerName,
    required double returnAmount,
    required String ownerName,
  }) {
    final ret = _formatAmount(returnAmount);
    final owner = ownerName.isNotEmpty ? ' - $ownerName' : '';
    return 'Loan completed! Total received: $ret from $customerName. '
        'Thank you!$owner';
  }

  /// Build SMS message for pre-closure.
  String buildPreClosureSms({
    required String customerName,
    required double payable,
    required String ownerName,
  }) {
    final pay = _formatAmount(payable);
    final owner = ownerName.isNotEmpty ? ' - $ownerName' : '';
    return 'Loan pre-closed for $customerName. '
        'Final amount: $pay. Schedule cancelled.$owner';
  }

  String _formatAmount(double amount) {
    return '\u20B9${amount.toStringAsFixed(0)}';
  }
}
