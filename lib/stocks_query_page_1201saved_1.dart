import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class StocksQueryPage extends StatefulWidget {
  const StocksQueryPage({super.key});

  @override
  _StocksQueryPageState createState() => _StocksQueryPageState();
}

class _StocksQueryPageState extends State<StocksQueryPage> {
  List<Map<String, dynamic>> stockData = [];
  bool isLoading = false;
  String errorMessage = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchStockData();
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
      _fetchStockData();
    });
  }

  Future<void> _fetchStockData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final dbPath = await _getDatabasePath('Options_MasterDB_P.db');
      final db = await openDatabase(dbPath);

      final symbols = await _getUserPreferredStocks(db);
      if (symbols.isEmpty) {
        setState(() {
          errorMessage = '無個股查詢資料';
        });
        return;
      }

      final apiData = await _fetchStocksFromAPI(symbols);

      final stockNames = await _getStockNames(db, symbols);

      setState(() {
        stockData = apiData.map((data) {
          final symbol = data['symbol'];
          final lastPrice = data['last_price'] ?? '-';
          final currency = data['currency'] ?? '-';
          final formattedPrice = lastPrice is num
              ? '${NumberFormat("#,##0.00").format(lastPrice)} ($currency)'
              : '$lastPrice ($currency)';

          final changeAmount = data['change_amount'] ?? '-';
          final formattedChangeAmount = changeAmount is num
              ? NumberFormat("#,##0.00").format(changeAmount)
              : changeAmount.toString();

          final changePercentage = _formatPercentage(data['change_percentage'] ?? '-');

          return {
            'symbol': symbol,
            'name': stockNames[symbol] ?? data['long_name'] ?? '未知股票',
            'formatted_price': formattedPrice,
            'change_amount': formattedChangeAmount,
            'change_percentage': changePercentage,
            'query_time': data['query_time'] ?? 'Unknown',
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        errorMessage = '查詢失敗：$e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

  Future<String> _getDatabasePath(String dbName) async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, dbName);
  }

  Future<List<String>> _getUserPreferredStocks(Database db) async {
    final result = await db.query('user_pref_stocks', columns: ['symbol']);
    return result.map((row) => row['symbol'] as String).toList();
  }

  Future<Map<String, String>> _getStockNames(Database db, List<String> symbols) async {
    final result = await db.query(
      'stocks',
      columns: ['symbol', 'name'],
      where: 'symbol IN (${List.filled(symbols.length, '?').join(', ')})',
      whereArgs: symbols,
    );
    return {for (var row in result) row['symbol'] as String: row['name'] as String};
  }

  Future<List<Map<String, dynamic>>> _fetchStocksFromAPI(List<String> symbols) async {
    final symbolsParam = symbols.join(',');
    final apiUrl = 'http://124.155.131.36:5004/api/stocks?symbols=$symbolsParam';

    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } else {
      throw Exception('Failed to fetch stocks: ${response.statusCode}');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          '個股即時查詢',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchStockData,
          ),
        ],
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
        itemCount: stockData.length,
        itemBuilder: (context, index) {
          final data = stockData[index];
          final name = data['name'] ?? '未知股票';
          final symbol = data['symbol'] ?? 'Unknown';
          final formattedPrice = data['formatted_price'] ?? '-';
          final formattedChangeAmount = data['change_amount'] ?? '-';
          final changePercentage = data['change_percentage'] ?? '-';
          final queryTime = data['query_time'] ?? 'Unknown';

          final isPositive =
          !formattedChangeAmount.startsWith('-'); // 判斷是否正值
          final changeColor =
          isPositive ? Colors.red : Colors.green; // 設定顏色

          // 動態背景色，根據索引交替
          final List<Color> backgroundColors = [
            Colors.blue.shade50,
            Colors.green.shade50,
            Colors.orange.shade50,
            Colors.purple.shade50,
            Colors.pink.shade50,
          ];
          final backgroundColor =
          backgroundColors[index % backgroundColors.length];

          return Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$name ($symbol)', // 股票名稱與代號
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '價格: $formattedPrice', // 格式化價格
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '漲跌額: $formattedChangeAmount (${changePercentage})', // 漲跌額後加上百分比
                  style: TextStyle(
                    fontSize: 12,
                    color: changeColor, // 顏色根據漲跌動態設定
                  ),
                ),
                Text(
                  '查詢時間: $queryTime', // 查詢時間
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
