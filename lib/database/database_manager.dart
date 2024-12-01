//*** database_manager.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  Database? _database;

  // 獲取資料庫路徑
  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'Options_MasterDB_P.db');
  }

  // 確保資料庫已經打開或初始化
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化資料庫
  Future<Database> _initDatabase() async {
    final dbPath = await _getDatabasePath();
    final dbExists = await databaseExists(dbPath);

    if (!dbExists) {
      throw Exception("資料庫不存在_db_manager！");
    }

    return openDatabase(
      dbPath,
      version: 1,
      onOpen: (db) async {
        print("資料庫已成功開啟_db_manager！");
      },
    );
  }

  // 通用查詢方法
  Future<List<Map<String, dynamic>>> queryTable(String tableName) async {
    final db = await database;
    return db.query(tableName);
  }

  // 複製資料庫檔案
  Future<void> copyDatabaseFromBytes(List<int> bytes) async {
    final dbPath = await _getDatabasePath();
    final file = File(dbPath);
    await file.writeAsBytes(bytes);
  }

  // 獲取所有資料表名稱
  Future<List<String>> getTableNames() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
    return result.map((row) => row['name'] as String).toList();
  }

  // 關閉資料庫
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print("資料庫已關閉_db_manager!");
    }
  }
}
