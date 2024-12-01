import 'package:flutter/material.dart';

class OptionsOrderPage extends StatefulWidget {
  const OptionsOrderPage({Key? key}) : super(key: key);

  @override
  _OptionsOrderPageState createState() => _OptionsOrderPageState();
}

class _OptionsOrderPageState extends State<OptionsOrderPage> {
  bool _isPanelVisible = false;

  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _expirationController = TextEditingController();
  final TextEditingController _strikeController = TextEditingController();
  final TextEditingController _sharesController = TextEditingController();
  final TextEditingController _orderPremiumController = TextEditingController();
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _dealSharesController = TextEditingController();
  final TextEditingController _dealPremiumController = TextEditingController();
  final TextEditingController _dealDateController = TextEditingController();

  String? _selectedKeyId;
  Map<String, dynamic>? _selectedRowData;
  List<Map<String, dynamic>> _orderData = [];

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
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 主畫面內容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            // 調整左右邊距
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
                            _buildInputField('銀行別', _bankController),
                            _buildInputField('股票代碼', _symbolController),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('到期日 (yyyy-mm-dd)',
                                _expirationController),
                            _buildInputField('執行價', _strikeController),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('下單股數', _sharesController),
                            _buildInputField('下單權利金',
                                _orderPremiumController),
                            _buildInputField('下單日 (yyyy-mm-dd)',
                                _orderDateController),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('成交股數', _dealSharesController),
                            _buildInputField('成交權利金',
                                _dealPremiumController),
                            _buildInputField('成交日 (yyyy-mm-dd)',
                                _dealDateController),
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
                  _buildSideButton('下單', Colors.lightBlue.shade100, () =>
                      _handleAction('下單')),
                  const SizedBox(height: 6), // 調整按鈕之間的上下間距
                  _buildSideButton('成交', Colors.lightBlue.shade200, () =>
                      _handleAction('成交')),
                  const SizedBox(height: 6),
                  _buildSideButton('平倉', Colors.lightBlue.shade300, () =>
                      _handleAction('平倉')),
                  const SizedBox(height: 6),
                  _buildSideButton('修改', Colors.lightBlue.shade400, () =>
                      _handleAction('修改')),
                  const SizedBox(height: 6),
                  _buildSideButton('刪除', Colors.lightBlue.shade500, () =>
                      _handleAction('刪除')),
                ],
              ),
            ),
          ),

          // 觸發按鈕
          Positioned(
            right: 0,
            top: MediaQuery
                .of(context)
                .size
                .height / 2 - 50,
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
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildInputField(String label, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2), // 縮小欄位左右邊距
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_orderData.isEmpty) {
      return const Center(child: Text('訂單資料表內尚無資料！'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        // 縮減欄位間距
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
        rows: _orderData.map((data) {
          return DataRow(
            selected: _selectedKeyId == data['key_id'], // 設定選中狀態
            onSelectChanged: (selected) {
              if (selected != null && selected) {
                setState(() {
                  _selectedKeyId = data['key_id'];
                  _selectedRowData = data;
                  _fillInputFields(data); // 填充輸入欄位
                });
              }
            },
            cells: [
              DataCell(Text(data['bank'] ?? '')),
              DataCell(Text(data['symbol'] ?? '')),
              DataCell(Text(data['expiration'] ?? '')),
              DataCell(Text(data['strike']?.toString() ?? '')),
              DataCell(Text(data['shares']?.toString() ?? '')),
              DataCell(Text(data['order_premium']?.toString() ?? '')),
              DataCell(Text(data['order_date'] ?? '')),
              DataCell(Text(data['deal_shares']?.toString() ?? '')),
              DataCell(Text(data['deal_premium']?.toString() ?? '')),
              DataCell(Text(data['deal_date'] ?? '')),
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
        textStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.red),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  void _fillInputFields(Map<String, dynamic> data) {
    _bankController.text = data['bank'] ?? '';
    _symbolController.text = data['symbol'] ?? '';
    _expirationController.text = data['expiration'] ?? '';
    _strikeController.text = data['strike']?.toString() ?? '';
    _sharesController.text = data['shares']?.toString() ?? '';
    _orderPremiumController.text = data['order_premium']?.toString() ?? '';
    _orderDateController.text = data['order_date'] ?? '';
    _dealSharesController.text = data['deal_shares']?.toString() ?? '';
    _dealPremiumController.text = data['deal_premium']?.toString() ?? '';
    _dealDateController.text = data['deal_date'] ?? '';
  }

  void _handleAction(String action) {
    switch (action) {
      case '下單':
        _handleOrder();
        break;
      case '成交':
        _handleDeal();
        break;
      case '平倉':
        _handleClose();
        break;
      case '修改':
        _handleUpdate();
        break;
      case '刪除':
        _handleDelete();
        break;
    }
    _togglePanel(); // 收起側邊按鈕
  }

  void _handleOrder() {
    if (_bankController.text.isEmpty ||
        _symbolController.text.isEmpty ||
        _expirationController.text.isEmpty ||
        _strikeController.text.isEmpty ||
        _sharesController.text.isEmpty ||
        _orderPremiumController.text.isEmpty ||
        _orderDateController.text.isEmpty) {
      _showMessage('下單資料不可空白，請填入正確資料！', Colors.red);
      return;
    }

    final keyId = 'ORD-${DateTime.now().toIso8601String()}';
    final newOrder = {
      'key_id': keyId,
      'bank': _bankController.text,
      'symbol': _symbolController.text,
      'expiration': _expirationController.text,
      'strike': int.tryParse(_strikeController.text) ?? 0,
      'shares': int.tryParse(_sharesController.text) ?? 0,
      'order_premium': double.tryParse(_orderPremiumController.text) ?? 0.0,
      'order_date': _orderDateController.text,
      'deal_shares': null,
      'deal_premium': null,
      'deal_date': null,
    };

    setState(() {
      _orderData.add(newOrder);
      _clearInputFields();
    });

    _showMessage('下單成功！', Colors.green);
  }

  void _handleDeal() {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行成交！', Colors.red);
      return;
    }

    if (_dealSharesController.text.isEmpty ||
        _dealPremiumController.text.isEmpty ||
        _dealDateController.text.isEmpty) {
      _showMessage('成交資料不可空白，請填入正確資料！', Colors.red);
      return;
    }

    setState(() {
      _selectedRowData!['deal_shares'] =
          int.tryParse(_dealSharesController.text);
      _selectedRowData!['deal_premium'] =
          double.tryParse(_dealPremiumController.text);
      _selectedRowData!['deal_date'] = _dealDateController.text;
      _clearInputFields();
    });

    _showMessage('成交成功！', Colors.green);
  }

  void _handleClose() {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行平倉！', Colors.red);
      return;
    }

    final currentShares = _selectedRowData!['shares'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController closingSharesController = TextEditingController(
            text: currentShares.toString());

        return AlertDialog(
          title: const Text('請輸入平倉股數'),
          content: TextField(
            controller: closingSharesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '平倉股數'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final closingShares = int.tryParse(
                    closingSharesController.text) ?? 0;
                Navigator.pop(context);

                setState(() {
                  if (closingShares == currentShares) {
                    // 完全平倉，刪除該筆資料
                    _orderData.removeWhere((order) =>
                    order['key_id'] == _selectedKeyId);
                    _showMessage('平倉成功！該筆訂單已移除。', Colors.green);
                  } else {
                    // 部分平倉，更新 shares
                    _selectedRowData!['shares'] = currentShares - closingShares;
                    _showMessage('部分平倉成功！', Colors.green);
                  }
                  _clearInputFields();
                });
              },
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }

  void _handleUpdate() {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行修改！', Colors.red);
      return;
    }

    setState(() {
      _selectedRowData!['bank'] = _bankController.text;
      _selectedRowData!['symbol'] = _symbolController.text;
      _selectedRowData!['expiration'] = _expirationController.text;
      _selectedRowData!['strike'] = int.tryParse(_strikeController.text);
      _selectedRowData!['shares'] = int.tryParse(_sharesController.text);
      _selectedRowData!['order_premium'] =
          double.tryParse(_orderPremiumController.text);
      _selectedRowData!['order_date'] = _orderDateController.text;
      _selectedRowData!['deal_shares'] =
          int.tryParse(_dealSharesController.text);
      _selectedRowData!['deal_premium'] =
          double.tryParse(_dealPremiumController.text);
      _selectedRowData!['deal_date'] = _dealDateController.text;
      _clearInputFields();
    });

    _showMessage('修改成功！', Colors.green);
  }

  void _handleDelete() {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行刪除！', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('確認刪除'),
            content: const Text('您確定要刪除此筆資料嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _orderData.removeWhere((order) =>
                    order['key_id'] == _selectedKeyId);
                    _clearInputFields();
                  });
                  Navigator.pop(context);
                  _showMessage('刪除成功！', Colors.green);
                },
                child: const Text('確認'),
              ),
            ],
          ),
    );
  }

  void _clearInputFields() {
    setState(() {
      _bankController.clear();
      _symbolController.clear();
      _expirationController.clear();
      _strikeController.clear();
      _sharesController.clear();
      _orderPremiumController.clear();
      _orderDateController.clear();
      _dealSharesController.clear();
      _dealPremiumController.clear();
      _dealDateController.clear();
      _selectedKeyId = null;
      _selectedRowData = null;
    });
  }


  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}