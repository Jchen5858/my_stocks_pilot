import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class IndicesQueryPage extends StatefulWidget {
  const IndicesQueryPage({Key? key}) : super(key: key);

  @override
  _IndicesQueryPageState createState() => _IndicesQueryPageState();
}

class _IndicesQueryPageState extends State<IndicesQueryPage> {
  List<Map<String, dynamic>> indicesData = [];
  bool isLoading = false;
  String errorMessage = '';
  Timer? _refreshTimer;

  String _formatPrice(dynamic price) {
    if (price is num) {
      final numberFormatter = NumberFormat("#,##0.00");
      return numberFormatter.format(price);
    }
    return price.toString();
  }

  String _formatPercentage(String percentage) {
    if (percentage.endsWith('%')) {
      percentage = percentage.substring(0, percentage.length - 1);
    }
    final numValue = double.tryParse(percentage);
    if (numValue != null) {
      final firstDecimalDigit = ((numValue * 10).truncate() % 10);
      if (firstDecimalDigit == 0) {
        return '${numValue.toStringAsFixed(3)}%';
      }
      return '${numValue.toStringAsFixed(2)}%';
    }
    return '$percentage%';
  }

  @override
  void initState() {
    super.initState();
    _initializeMarketIndices();
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _initializeMarketIndices();
    });
  }

  Future<void> _initializeMarketIndices() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final dbPath = await _getDatabasePath('Options_MasterDB_P.db');
      final dbExists = await File(dbPath).exists();

      if (!dbExists) {
        _showDatabaseWarning('資料庫尚未轉入，將使用預設大盤指數！');
        await _fetchMarketIndices(_getDefaultIndices());
        return;
      }

      final db = await openDatabase(dbPath);
      if (!await _checkTableExists(db, 'market_indices')) {
        _showDatabaseWarning('資料表尚未建立，將使用預設大盤指數！');
        await _fetchMarketIndices(_getDefaultIndices());
        return;
      }

      final indices = await _getMarketIndicesFromDb(db);
      if (indices.isEmpty) {
        _showDatabaseWarning('資料表內容為空，將使用預設大盤指數！');
        await _fetchMarketIndices(_getDefaultIndices());
        return;
      }

      await _fetchMarketIndices(indices);
    } catch (e) {
      setState(() {
        errorMessage = '初始化時發生錯誤：$e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _fetchMarketIndices(List<Map<String, String>> indices) async {
    final symbols = indices.map((index) => index['symbol']!).join(',');
    final apiUrl =
        'http://124.155.131.36:5004/api/market_indices?indices=$symbols';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          indicesData = data.map((apiData) {
            final localIndex = indices.firstWhere(
                  (index) => index['symbol'] == apiData['indices_code'],
              orElse: () => {'chinese_name': '未知指數', 'country': '未知'},
            );
            return {
              'indices_code': apiData['indices_code'] ?? 'Unknown',
              'last_price': apiData['last_price'] ?? '-',
              'currency': apiData['currency'] ?? '-',
              'change_amount': apiData['change_amount'] ?? '-',
              'change_percentage': apiData['change_percentage'] ?? '-',
              'query_time': apiData['query_time'] ?? 'Unknown',
              'chinese_name': localIndex['chinese_name'] ?? '未知指數',
              'country': localIndex['country'] ?? '未知',
            };
          }).toList().cast<Map<String, dynamic>>();  // 確保是 Map<String, dynamic>
        });
      } else {
        setState(() {
          errorMessage = '資料載入失敗: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '發生錯誤: $e';
      });
    }
  }

  Future<String> _getDatabasePath(String dbName) async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, dbName);
  }

  Future<bool> _checkTableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?", [tableName]);
    return result.isNotEmpty;
  }

  Future<List<Map<String, String>>> _getMarketIndicesFromDb(Database db) async {
    final List<Map<String, dynamic>> result =
    await db.query('market_indices', columns: ['symbol', 'chinese_name', 'country']);
    return result.map((row) {
      return {
        'symbol': row['symbol'] as String,
        'chinese_name': row['chinese_name'] as String,
        'country': row['country'] as String,
      };
    }).toList();
  }

  void _showDatabaseWarning(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('資料庫警告'),
            content: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('確定'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  List<Map<String, String>> _getDefaultIndices() {
    return [
      {'symbol': '^GSPC', 'chinese_name': '標普500指數', 'country': 'US'},
      {'symbol': '^DJI', 'chinese_name': '道瓊工業指數', 'country': 'US'},
      {'symbol': '^IXIC', 'chinese_name': '納斯達克指數', 'country': 'US'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '', // 移除大盤指數的文字
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,  // 保持 title 居中
        actions: [],
        flexibleSpace: Align(
          alignment: Alignment.center,  // 設定 refresh 按鈕在中間
          child: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initializeMarketIndices(),
            tooltip: '手動更新',
          ),
        ),
      ),

      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '更新中...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 3 / 2,
        ),
        itemCount: indicesData.length,
        itemBuilder: (context, index) {
          final data = indicesData[index];
          final chineseName = data['chinese_name'] ?? '未知指數';
          final indicesCode = data['indices_code'] ?? 'Unknown';
          final lastPrice = data['last_price'] ?? '-';
          final changeAmount = data['change_amount'] ?? '-';
          final changePercentage = data['change_percentage'] ?? '-';
          final queryTime = data['query_time'] ?? '未知時間';

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chineseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('代碼: $indicesCode'),
                  Text('最後價格: \$${_formatPrice(lastPrice)}'),
                  Text('變動: ${_formatPrice(changeAmount)}'),
                  Text('變動幅度: ${_formatPercentage(changePercentage)}'),
                  Text('查詢時間: $queryTime'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
