import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '設定頁面',
        style: TextStyle(fontSize: 24, color: Colors.teal[700]),
      ),
    );
  }
}
