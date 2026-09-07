import 'package:sqflite/sqflite.dart' as sqflite;
import '../database_helper.dart';
import '../../models/loan.dart';

class LoanDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Loan loan) async {
    final db = await _dbHelper.database;
    return await db.insert('loans', loan.toMap());
  }

  Future<Loan?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('loans', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  Future<Loan?> getActiveLoanByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'loans',
      where: 'customer_id = ? AND status IN (?, ?)',
      whereArgs: [customerId, 'active', 'overdue'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  Future<List<Loan>> getByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'loans',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  Future<List<Loan>> getByStatus(LoanStatus status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'loans',
      where: 'status = ?',
      whereArgs: [status.dbValue],
    );
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  Future<List<Loan>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('loans', orderBy: 'created_at DESC');
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  Future<int> update(Loan loan) async {
    final db = await _dbHelper.database;
    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> updateStatus(int loanId, LoanStatus status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'loans',
      {'status': status.dbValue},
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }

  // Dashboard aggregation queries
  Future<double> getTotalGiven() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(principal), 0) as total FROM loans WHERE status != 'cancelled'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalCollected() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(collected_amount), 0) as total FROM collection_entries",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpectedProfit() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(profit), 0) as total FROM loans WHERE status != 'cancelled'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> countByStatus(LoanStatus status) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM loans WHERE status = ?",
      [status.dbValue],
    );
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Loan>> getActiveLoans() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'loans',
      where: "status IN (?, ?)",
      whereArgs: ['active', 'overdue'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  // For backup
  Future<List<Map<String, dynamic>>> getAllRaw() async {
    final db = await _dbHelper.database;
    return await db.query('loans');
  }

  Future<void> insertRaw(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    await db.insert('loans', data);
  }
}
