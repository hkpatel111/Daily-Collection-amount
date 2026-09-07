import '../database_helper.dart';
import '../../models/collection_entry.dart';

class CollectionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(CollectionEntry entry) async {
    final db = await _dbHelper.database;
    return await db.insert('collection_entries', entry.toMap());
  }

  Future<CollectionEntry?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'collection_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CollectionEntry.fromMap(maps.first);
  }

  Future<List<CollectionEntry>> getByLoanId(int loanId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'collection_entries',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'collection_date DESC, created_at DESC',
    );
    return maps.map((m) => CollectionEntry.fromMap(m)).toList();
  }

  Future<List<CollectionEntry>> getByScheduleEntryId(int scheduleEntryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'collection_entries',
      where: 'schedule_entry_id = ?',
      whereArgs: [scheduleEntryId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => CollectionEntry.fromMap(m)).toList();
  }

  Future<List<CollectionEntry>> getByDate(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'collection_entries',
      where: 'collection_date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => CollectionEntry.fromMap(m)).toList();
  }

  Future<double> getTotalCollectedByLoan(int loanId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(collected_amount), 0) as total FROM collection_entries WHERE loan_id = ?',
      [loanId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalCollectedByDate(String date) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(collected_amount), 0) as total FROM collection_entries WHERE collection_date = ?',
      [date],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalOverdueInterestByLoan(int loanId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(overdue_interest), 0) as total FROM collection_entries WHERE loan_id = ?',
      [loanId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> update(CollectionEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'collection_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> updateOverdueInterest(
      int entryId, double overdueInterest, String updatedAt) async {
    final db = await _dbHelper.database;
    return await db.update(
      'collection_entries',
      {
        'overdue_interest': overdueInterest,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<double> getTotalShortfallByLoan(int loanId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(shortfall), 0) as total FROM collection_entries WHERE loan_id = ?',
      [loanId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // For backup
  Future<List<Map<String, dynamic>>> getAllRaw() async {
    final db = await _dbHelper.database;
    return await db.query('collection_entries');
  }

  Future<void> insertRaw(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    await db.insert('collection_entries', data);
  }
}
