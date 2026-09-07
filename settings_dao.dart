import '../database_helper.dart';
import '../../models/settings.dart';

class SettingsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<AppSettings> getSettings() async {
    final db = await _dbHelper.database;
    final maps = await db.query('settings', where: 'id = 1', limit: 1);
    if (maps.isEmpty) {
      // Insert default settings if not present
      final defaultSettings = AppSettings();
      await db.insert('settings', defaultSettings.toMap());
      return defaultSettings;
    }
    return AppSettings.fromMap(maps.first);
  }

  Future<int> updateSettings(AppSettings settings) async {
    final db = await _dbHelper.database;
    return await db.update(
      'settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }
}
