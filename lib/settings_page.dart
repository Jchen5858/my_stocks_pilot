import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/Options_MasterDB_P.db';
  }

  // 從 Google Drive 複製資料庫 Options_MasterDB_P.db
  Future<void> _copyFromGoogleDrive(BuildContext context) async {
    const fileId = '167cTA_5AoS7kHGy8vBwwcUym6O_U9GT1';
    final url = 'https://drive.google.com/uc?export=download&id=$fileId';
    https://drive.google.com/file/d/167cTA_5AoS7kHGy8vBwwcUym6O_U9GT1/view?usp=drive_link
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(strokeWidth: 5),
      ),
    );

    try {
      final response = await http.get(Uri.parse(url));
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        final dbPath = await _getDatabasePath();
        final file = File(dbPath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('資料庫成功下載並儲存至本地！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下載失敗，HTTP 狀態碼：${response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下載失敗：$e')),
      );
    }
  }

  // 顯示所有資料表
  Future<void> _showAllTables(BuildContext context, {required Function(String) onTableTap}) async {
    try {
      final db = await openDatabase(await _getDatabasePath());
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");

      if (result.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('資料表列表'),
            content: SingleChildScrollView(
              child: ListBody(
                children: result
                    .map((row) => ListTile(
                  title: Text(row['name'].toString()),
                  onTap: () async {
                    Navigator.pop(context); // 返回資料表列表
                    onTableTap(row['name'].toString());
                  },
                ))
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("關閉"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無資料表可驗證')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('驗證結構失敗: $e')),
      );
    }
  }

  // 顯示資料表結構
  Future<void> _showTableStructure(BuildContext context, String tableName) async {
    try {
      final db = await openDatabase(await _getDatabasePath());
      final result = await db.rawQuery("PRAGMA table_info('$tableName')");

      if (result.isNotEmpty) {
        final fields = result
            .map((row) => "欄位名稱：${row['name']}, 資料型態：${row['type']}")
            .join("\n");

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('資料表結構: $tableName'),
            content: Text(fields),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAllTables(context, onTableTap: (name) async {
                    await _showTableStructure(context, name);
                  });
                },
                child: const Text("返回列表"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此資料表無欄位資訊！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('檢視資料失敗: $e')),
      );
    }
  }

  // 顯示資料表內容
  Future<void> _showTableData(BuildContext context, String tableName) async {
    try {
      final db = await openDatabase(await _getDatabasePath());
      final result = await db.query(tableName);

      if (result.isNotEmpty) {
        final columnNames = result.first.keys.toList();

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('資料表: $tableName'),
            content: SingleChildScrollView(
              child: DataTable(
                columns: columnNames
                    .map((col) => DataColumn(
                  label: Text(
                    col,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ))
                    .toList(),
                rows: result.map((row) {
                  return DataRow(
                    cells: row.values.map((value) {
                      return DataCell(Text(value.toString()));
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAllTables(context, onTableTap: (name) async {
                    await _showTableData(context, name);
                  });
                },
                child: const Text("返回列表"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此資料表無資料')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('檢視資料失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> actions = ['複製資料庫', '驗證資料庫', '驗證資料表', '設定資料表'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '股票資料建檔',
          style: TextStyle(
            fontSize: 24, // 字體大小
            fontWeight: FontWeight.bold, // 字體粗細
          ),
        ),
        centerTitle: true, // 置中
        // backgroundColor: Color(0xFF81C784), // Tiffany 藍色背景
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () async {
              if (action == '複製資料庫') {
                await _copyFromGoogleDrive(context);
              } else if (action == '驗證資料庫') {
                await _showAllTables(context, onTableTap: (name) async {
                  await _showTableStructure(context, name);
                });
              } else if (action == '驗證資料表') {
                await _showAllTables(context, onTableTap: (name) async {
                  await _showTableData(context, name);
                });
              } else if (action == '設定資料表') {
                // Add logic for "設定資料表" action here
              }
            },
            child: Card(
              color: Colors.deepOrangeAccent,
              elevation: 4,
              child: Center(
                child: Text(
                  action,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
