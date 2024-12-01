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
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: stockData.length,
        itemBuilder: (context, index) {
          final data = stockData[index];
          final name = data['name'] ?? '未知股票';
          final symbol = data['symbol'] ?? 'Unknown';
          final formattedPrice = data['formatted_price'] ?? '-';
          final formattedChangeAmount = data['change_amount'] ?? '-';
          final changePercentage = data['change_percentage'] ?? '-';
          final queryTime = data['query_time'] ?? 'Unknown';

          final isPositive = formattedChangeAmount.startsWith('-') == false;
          final changeColor = isPositive ? Colors.green : Colors.red;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('代號: $symbol'),
                  Text('價格: $formattedPrice'),
                  Text('漲跌額: $formattedChangeAmount'),
                  Text('漲跌幅: $changePercentage'),
                  Text('查詢時間: $queryTime'),
                ],
              ),
              trailing: Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: changeColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
