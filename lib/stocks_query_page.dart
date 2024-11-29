import 'package:flutter/material.dart';

class StocksQueryPage extends StatelessWidget {
  const StocksQueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '股票查詢頁面',
        style: TextStyle(fontSize: 24, color: Colors.teal[700]),
      ),
    );
  }
}
