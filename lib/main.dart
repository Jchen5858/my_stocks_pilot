import 'package:flutter/material.dart';
import 'indices_query_page.dart';
import 'stocks_query_page.dart';
import 'options_order_page.dart';
import 'stocks_order_page.dart';
import 'settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '股票小助手',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 預設為首頁
  final PageController _pageController = PageController(); // 定義 PageController

  final List<Widget> _pages = [
    const IndicesQueryPage(), // 大盤查詢功能頁
    const StocksQueryPage(), // 股票查詢功能頁
    const OptionsOrderPage(), // 選擇權查詢功能頁
    const StocksOrderPage(), // 股票管理功能頁
    const SettingsPage(), // 設定功能頁
  ];

  @override
  void dispose() {
    _pageController.dispose(); // 清理 PageController
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.ease); // 切換頁面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                '股票小助手',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Text(
              'v1.0.0',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0) // 只在首頁顯示使用說明按鈕
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showHelpDialog(context);
              },
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '大盤'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: '股價'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: '選擇權'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '訂單'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("使用說明"),
        content: const Text(
            "這是一個股票管理應用程式，提供股價、選擇權查詢等功能。\n\n"
                "1. 點擊主頁查看大盤指數。\n"
                "2. 使用股價查詢查看特定股票資料。\n"
                "3. 選擇權查詢提供衍生性商品的資料。\n"
                "4. 訂單和設定可以管理您的交易和應用配置。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("關閉"),
          ),
        ],
      ),
    );
  }
}
