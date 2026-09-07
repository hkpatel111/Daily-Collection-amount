import '../database_helper.dart';
import '../../models/schedule_entry.dart';

class ScheduleDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(ScheduleEntry entry) async {
    final db = await _dbHelper.database;
    return await db.insert('schedule_entries', entry.toMap());
  }

  Future<int> insertBatch(List<ScheduleEntry> entries) async {
    final db = await _dbHelper.database;
    int count = 0;
    final batch = db.batch();
    for (final entry in entries) {
      batch.insert('schedule_entries', entry.toMap());
      count++;
    }
    await batch.commit(noResult: true);
    return count;
  }

  Future<ScheduleEntry?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ScheduleEntry.fromMap(maps.first);
  }

  Future<List<ScheduleEntry>> getByLoanId(int loanId,
      {int? limit, int offset = 0}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_entries',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'day_number DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => ScheduleEntry.fromMap(m)).toList();
  }

  Future<ScheduleEntry?> getByLoanIdAndDay(int loanId, int dayNumber) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_entries',
      where: 'loan_id = ? AND day_number = ?',
      whereArgs: [loanId, dayNumber],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ScheduleEntry.fromMap(maps.first);
  }

  Future<ScheduleEntry?> getByLoanIdAndDate(int loanId, String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_entries',
      where: 'loan_id = ? AND scheduled_date = ?',
      whereArgs: [loanId, date],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ScheduleEntry.fromMap(maps.first);
  }

  Future<List<ScheduleEntry>> getByDate(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_entries',
      where: 'scheduled_date = ? AND status = ? AND is_holiday = 0',
      whereArgs: [date, 'pending'],
      orderBy: 'loan_id',
    );
    return maps.map((m) => ScheduleEntry.fromMap(m)).toList();
  }

  Future<int> update(ScheduleEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'schedule_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> updateStatus(int entryId, ScheduleEntryStatus status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'schedule_entries',
      {'status': status.dbValue},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<int> cancelPendingByLoan(int loanId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'schedule_entries',
      {'status': 'cancelled'},
      where: 'loan_id = ? AND status = ?',
      whereArgs: [loanId, 'pending'],
    );
  }

  Future<List<ScheduleEntry>> getOverdueEntries(int loanId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_entries',
      where: 'loan_id = ? AND status IN (?, ?)',
      whereArgs: [loanId, 'missed', 'partial'],
      orderBy: 'day_number ASC',
    );
    return maps.map((m) => ScheduleEntry.fromMap(m)).toList();
  }

  Future<int> countPendingByLoan(int loanId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM schedule_entries WHERE loan_id = ? AND status = ?',
      [loanId, 'pending'],
    );
    final values = result.first['count'];
    return values is int ? values : (values as num).toInt();
  }

  // For backup
  Future<List<Map<String, dynamic>>> getAllRaw() async {
    final db = await _dbHelper.database;
    return await db.query('schedule_entries');
  }

  Future<void> insertRaw(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    await db.insert('schedule_entries', data);
  }
}
