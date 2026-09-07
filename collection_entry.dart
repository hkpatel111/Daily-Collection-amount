class CollectionEntry {
  final int? id;
  final int loanId;
  final int scheduleEntryId;
  final String collectionDate;
  final double expectedAmount;
  final double collectedAmount;
  final double shortfall;
  final bool isMissed;
  double overdueInterest;
  String? note;
  final String createdAt;
  String updatedAt;

  CollectionEntry({
    this.id,
    required this.loanId,
    required this.scheduleEntryId,
    required this.collectionDate,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.shortfall,
    this.isMissed = false,
    this.overdueInterest = 0.0,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_id': loanId,
      'schedule_entry_id': scheduleEntryId,
      'collection_date': collectionDate,
      'expected_amount': expectedAmount,
      'collected_amount': collectedAmount,
      'shortfall': shortfall,
      'is_missed': isMissed ? 1 : 0,
      'overdue_interest': overdueInterest,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CollectionEntry.fromMap(Map<String, dynamic> map) {
    return CollectionEntry(
      id: map['id'] as int?,
      loanId: map['loan_id'] as int,
      scheduleEntryId: map['schedule_entry_id'] as int,
      collectionDate: map['collection_date'] as String,
      expectedAmount: (map['expected_amount'] as num).toDouble(),
      collectedAmount: (map['collected_amount'] as num).toDouble(),
      shortfall: (map['shortfall'] as num).toDouble(),
      isMissed: (map['is_missed'] as int) == 1,
      overdueInterest: (map['overdue_interest'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  CollectionEntry copyWith({
    int? id,
    int? loanId,
    int? scheduleEntryId,
    String? collectionDate,
    double? expectedAmount,
    double? collectedAmount,
    double? shortfall,
    bool? isMissed,
    double? overdueInterest,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return CollectionEntry(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      scheduleEntryId: scheduleEntryId ?? this.scheduleEntryId,
      collectionDate: collectionDate ?? this.collectionDate,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      shortfall: shortfall ?? this.shortfall,
      isMissed: isMissed ?? this.isMissed,
      overdueInterest: overdueInterest ?? this.overdueInterest,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
