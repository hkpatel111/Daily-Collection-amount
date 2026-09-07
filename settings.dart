class AppSettings {
  final int id;
  int gracePeriodDays;
  bool sundayHolidayEnabled;
  int defaultedThresholdDays;
  bool smsEnabled;
  bool smsOnPayment;
  bool smsOnMissed;
  bool smsOnCompletion;
  bool smsOnPreclosure;
  bool smsAutoSend;
  String ownerName;

  AppSettings({
    this.id = 1,
    this.gracePeriodDays = 1,
    this.sundayHolidayEnabled = false,
    this.defaultedThresholdDays = 15,
    this.smsEnabled = true,
    this.smsOnPayment = true,
    this.smsOnMissed = true,
    this.smsOnCompletion = true,
    this.smsOnPreclosure = true,
    this.smsAutoSend = false,
    this.ownerName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grace_period_days': gracePeriodDays,
      'sunday_holiday_enabled': sundayHolidayEnabled ? 1 : 0,
      'defaulted_threshold_days': defaultedThresholdDays,
      'sms_enabled': smsEnabled ? 1 : 0,
      'sms_on_payment': smsOnPayment ? 1 : 0,
      'sms_on_missed': smsOnMissed ? 1 : 0,
      'sms_on_completion': smsOnCompletion ? 1 : 0,
      'sms_on_preclosure': smsOnPreclosure ? 1 : 0,
      'sms_auto_send': smsAutoSend ? 1 : 0,
      'owner_name': ownerName,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int? ?? 1,
      gracePeriodDays: map['grace_period_days'] as int? ?? 1,
      sundayHolidayEnabled: (map['sunday_holiday_enabled'] as int? ?? 0) == 1,
      defaultedThresholdDays: map['defaulted_threshold_days'] as int? ?? 15,
      smsEnabled: (map['sms_enabled'] as int? ?? 1) == 1,
      smsOnPayment: (map['sms_on_payment'] as int? ?? 1) == 1,
      smsOnMissed: (map['sms_on_missed'] as int? ?? 1) == 1,
      smsOnCompletion: (map['sms_on_completion'] as int? ?? 1) == 1,
      smsOnPreclosure: (map['sms_on_preclosure'] as int? ?? 1) == 1,
      smsAutoSend: (map['sms_auto_send'] as int? ?? 0) == 1,
      ownerName: map['owner_name'] as String? ?? '',
    );
  }

  AppSettings copyWith({
    int? id,
    int? gracePeriodDays,
    bool? sundayHolidayEnabled,
    int? defaultedThresholdDays,
    bool? smsEnabled,
    bool? smsOnPayment,
    bool? smsOnMissed,
    bool? smsOnCompletion,
    bool? smsOnPreclosure,
    bool? smsAutoSend,
    String? ownerName,
  }) {
    return AppSettings(
      id: id ?? this.id,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      sundayHolidayEnabled: sundayHolidayEnabled ?? this.sundayHolidayEnabled,
      defaultedThresholdDays: defaultedThresholdDays ?? this.defaultedThresholdDays,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      smsOnPayment: smsOnPayment ?? this.smsOnPayment,
      smsOnMissed: smsOnMissed ?? this.smsOnMissed,
      smsOnCompletion: smsOnCompletion ?? this.smsOnCompletion,
      smsOnPreclosure: smsOnPreclosure ?? this.smsOnPreclosure,
      smsAutoSend: smsAutoSend ?? this.smsAutoSend,
      ownerName: ownerName ?? this.ownerName,
    );
  }
}
