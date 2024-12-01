import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    // if (_database != null) return _database!;
    if (_database != null) {
      print("Using existing database instance."); // 確認是否使用已建立的資料庫實例
      return _database!;
    }

    print("Initializing new database instance."); // 確認是否初始化新的資料庫實例
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'Options_MasterDB.db');
    return openDatabase(
      path,
      version: 1,
    );
  }

  Future<List<Map<String, dynamic>>> query(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data);
  }

  Future<int> update(String table, Map<String, dynamic> data, String keyId) async {
    final db = await database;
    return db.update(table, data, where: 'key_id = ?', whereArgs: [keyId]);
  }

  Future<int> delete(String table, String keyId) async {
    final db = await database;
    return db.delete(table, where: 'key_id = ?', whereArgs: [keyId]);
  }
}
