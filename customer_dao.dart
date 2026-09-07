import '../database_helper.dart';
import '../../models/customer.dart';

class CustomerDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<Customer?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Customer>> getAll({bool activeOnly = true}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<List<Customer>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'is_active = 1 AND (name LIKE ? OR mobile LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<int> update(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> softDelete(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasActiveLoan(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'loans',
      where: 'customer_id = ? AND status IN (?, ?)',
      whereArgs: [customerId, 'active', 'overdue'],
    );
    return maps.isNotEmpty;
  }

  // For backup
  Future<List<Map<String, dynamic>>> getAllRaw() async {
    final db = await _dbHelper.database;
    return await db.query('customers');
  }

  Future<void> insertRaw(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    await db.insert('customers', data);
  }
}
