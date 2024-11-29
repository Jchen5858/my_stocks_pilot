import 'package:flutter/material.dart';

class StocksOrderPage extends StatelessWidget {
  const StocksOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '股票管理頁面',
        style: TextStyle(fontSize: 24, color: Colors.teal[700]),
      ),
    );
  }
}
