import 'package:flutter/material.dart';

class OptionsOrderPage extends StatefulWidget {
  const OptionsOrderPage({Key? key}) : super(key: key);

  @override
  _OptionsOrderPageState createState() => _OptionsOrderPageState();
}

class _OptionsOrderPageState extends State<OptionsOrderPage> {
  bool _isPanelVisible = false;

  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '選擇權訂單作業',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 主畫面內容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0), // 調整左右邊距
            child: Column(
              children: [
                // 資料輸入區
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8), // 減少內部邊距
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildInputField('銀行別'),
                            _buildInputField('股票代碼'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('到期日 (yyyy-mm-dd)'),
                            _buildInputField('執行價'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('下單股數'),
                            _buildInputField('下單權利金'),
                            _buildInputField('下單日 (yyyy-mm-dd)'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('成交股數'),
                            _buildInputField('成交權利金'),
                            _buildInputField('成交日 (yyyy-mm-dd)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 資料列表
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8), // 減少上下邊距
                    child: Padding(
                      padding: const EdgeInsets.all(4), // 調整資料列表內的邊距
                      child: _buildDataTable(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 側邊按鈕容器
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right: _isPanelVisible ? 8 : -100,
            top: 150,
            bottom: 150,
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 控制按鈕的排列方式
                children: [
                  _buildSideButton('下單', Colors.lightBlue.shade100, () => _handleAction('下單')),
                  const SizedBox(height: 6), // 調整按鈕之間的上下間距
                  _buildSideButton('成交', Colors.lightBlue.shade200, () => _handleAction('成交')),
                  const SizedBox(height: 6),
                  _buildSideButton('平倉', Colors.lightBlue.shade300, () => _handleAction('平倉')),
                  const SizedBox(height: 6),
                  _buildSideButton('修改', Colors.lightBlue.shade400, () => _handleAction('修改')),
                  const SizedBox(height: 6),
                  _buildSideButton('刪除', Colors.lightBlue.shade500, () => _handleAction('刪除')),
                ],
              ),
            ),
          ),


          // 觸發按鈕
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height / 2 - 50,
            child: GestureDetector(
              onTap: _togglePanel,
              child: Container(
                width: 30,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      '按鈕',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2), // 縮小欄位左右邊距
        child: TextField(
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final List<Map<String, dynamic>> dummyData = [
      {
        'bank': '銀行A',
        'symbol': 'AAPL',
        'expiration': '2024-12-31',
        'strike': 150,
        'shares': 100,
        'order_premium': 5.5,
        'order_date': '2024-11-01',
        'deal_shares': 50,
        'deal_premium': 3.0,
        'deal_date': '2024-11-15',
      },
    ];

    if (dummyData.isEmpty) {
      return const Center(child: Text('訂單資料表內尚無資料！'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12, // 縮減欄位間距
        dataRowHeight: 30,
        headingRowHeight: 40,
        columns: const [
          DataColumn(label: Text('銀行別')),
          DataColumn(label: Text('股票代碼')),
          DataColumn(label: Text('到期日')),
          DataColumn(label: Text('執行價')),
          DataColumn(label: Text('下單股數')),
          DataColumn(label: Text('下單權利金')),
          DataColumn(label: Text('下單日')),
          DataColumn(label: Text('成交股數')),
          DataColumn(label: Text('成交權利金')),
          DataColumn(label: Text('成交日')),
        ],
        rows: dummyData.map((data) {
          return DataRow(
            cells: [
              DataCell(Text(data['bank'])),
              DataCell(Text(data['symbol'])),
              DataCell(Text(data['expiration'])),
              DataCell(Text(data['strike'].toString())),
              DataCell(Text(data['shares'].toString())),
              DataCell(Text(data['order_premium'].toString())),
              DataCell(Text(data['order_date'])),
              DataCell(Text(data['deal_shares'].toString())),
              DataCell(Text(data['deal_premium'].toString())),
              DataCell(Text(data['deal_date'])),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSideButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  void _handleAction(String action) {
    print('執行操作：$action');
    _togglePanel();
  }
}
