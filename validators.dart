class Validators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? validateAmount(String? value, {String label = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Enter a valid $label';
    }
    return null;
  }

  static String? validateReturnAmount(String? value, double principal) {
    final error = validateAmount(value, label: 'Return amount');
    if (error != null) return error;
    final amount = double.parse(value!);
    if (amount <= principal) {
      return 'Return amount must be greater than principal';
    }
    return null;
  }

  static String? validateDailyInstallment(String? value, double returnAmount) {
    final error = validateAmount(value, label: 'Daily installment');
    if (error != null) return error;
    final amount = double.parse(value!);
    if (amount > returnAmount) {
      return 'Daily installment cannot exceed return amount';
    }
    return null;
  }
}
