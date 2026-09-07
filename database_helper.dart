import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  static const int _dbVersion = 1;
  static const String _dbName = 'daily_collection.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        principal REAL NOT NULL,
        return_amount REAL NOT NULL,
        daily_installment REAL NOT NULL,
        total_days INTEGER NOT NULL,
        profit REAL NOT NULL,
        daily_interest_rate REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        last_day_adjusted_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        scheduled_date TEXT NOT NULL,
        expected_amount REAL NOT NULL,
        is_holiday INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (loan_id) REFERENCES loans (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE collection_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        schedule_entry_id INTEGER NOT NULL,
        collection_date TEXT NOT NULL,
        expected_amount REAL NOT NULL,
        collected_amount REAL NOT NULL,
        shortfall REAL NOT NULL DEFAULT 0,
        is_missed INTEGER NOT NULL DEFAULT 0,
        overdue_interest REAL NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (loan_id) REFERENCES loans (id),
        FOREIGN KEY (schedule_entry_id) REFERENCES schedule_entries (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        grace_period_days INTEGER NOT NULL DEFAULT 1,
        sunday_holiday_enabled INTEGER NOT NULL DEFAULT 0,
        defaulted_threshold_days INTEGER NOT NULL DEFAULT 15,
        sms_enabled INTEGER NOT NULL DEFAULT 1,
        sms_on_payment INTEGER NOT NULL DEFAULT 1,
        sms_on_missed INTEGER NOT NULL DEFAULT 1,
        sms_on_completion INTEGER NOT NULL DEFAULT 1,
        sms_on_preclosure INTEGER NOT NULL DEFAULT 1,
        sms_auto_send INTEGER NOT NULL DEFAULT 0,
        owner_name TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Insert default settings row
    await db.insert('settings', {
      'id': 1,
      'grace_period_days': 1,
      'sunday_holiday_enabled': 0,
      'defaulted_threshold_days': 15,
      'sms_enabled': 1,
      'sms_on_payment': 1,
      'sms_on_missed': 1,
      'sms_on_completion': 1,
      'sms_on_preclosure': 1,
      'sms_auto_send': 0,
      'owner_name': '',
    });

    // Indexes for performance
    await db.execute('CREATE INDEX idx_loans_customer_id ON loans(customer_id)');
    await db.execute('CREATE INDEX idx_schedule_loan_id ON schedule_entries(loan_id)');
    await db.execute('CREATE INDEX idx_schedule_date ON schedule_entries(scheduled_date)');
    await db.execute('CREATE INDEX idx_collection_loan_id ON collection_entries(loan_id)');
    await db.execute('CREATE INDEX idx_collection_schedule_id ON collection_entries(schedule_entry_id)');
    await db.execute('CREATE INDEX idx_collection_date ON collection_entries(collection_date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will go here
  }

  // Raw DB access for backup/restore
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Execute raw SQL (for backup import)
  Future<void> executeRaw(String sql) async {
    final db = await database;
    await db.execute(sql);
  }

  // Delete all data (for restore)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('collection_entries');
    await db.delete('schedule_entries');
    await db.delete('loans');
    await db.delete('customers');
  }
}
