import 'package:flutter/material.dart';
import 'database_helper.dart'; // 匯入資料庫助手類

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

  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print("Loading data from Options_Order_Bag..."); // 確認進入 _loadData 方法
    final data = await dbHelper.query('Options_Order_Bag');
    print("Data loaded successfully: ${data.length} rows."); // 確認查詢結果行數
    setState(() {
      _orderData = data;
    });
  }

  void _handleAction(String action) async {
    switch (action) {
      case '下單':
        await _handleOrder();
        break;
      case '成交':
        await _handleDeal();
        break;
      case '平倉':
        await _handleClose();
        break;
      case '修改':
        await _handleUpdate();
        break;
      case '刪除':
        await _handleDelete();
        break;
      default:
        print("未知的操作: $action");
    }
    _togglePanel(); // 收起側邊按鈕
  }

  Future<void> _handleOrder() async {
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

    final newOrder = {
      'key_id': 'ORD-${DateTime.now().toIso8601String()}',
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
    print("Inserting new order: $newOrder"); // 確認插入的資料內容
    // await dbHelper.insert('Options_Order_Bag', newOrder);
    // await _loadData();
    // _clearInputFields();
    try {
      await dbHelper.insert('Options_Order_Bag', newOrder);
      print("Insert successful."); // 確認插入成功
      await _loadData(); // 重新載入資料
    } catch (e) {
      print("Insert failed: $e"); // 捕獲並打印錯誤
    }
    _clearInputFields();
  }
    _showMessage('下單成功！', Colors.green);
  }

  Future<void> _handleDeal() async {
    if (_selectedRowData == null) {
      print("No row selected for deal."); // 確認是否有選中資料
      _showMessage('請選擇一筆資料進行成交！', Colors.red);
      return;
    }

    if (_dealSharesController.text.isEmpty ||
        _dealPremiumController.text.isEmpty ||
        _dealDateController.text.isEmpty) {
      _showMessage('成交資料不可空白，請填入正確資料！', Colors.red);
      return;
    }

    final updatedData = {
      'deal_shares': int.tryParse(_dealSharesController.text),
      'deal_premium': double.tryParse(_dealPremiumController.text),
      'deal_date': _dealDateController.text,
    };
    print("Updating deal data: $updatedData"); // 確認更新的資料內容
    // await dbHelper.update('Options_Order_Bag', updatedData, _selectedKeyId!);
    // await _loadData();
    // _clearInputFields();

    try {
      await dbHelper.update('Options_Order_Bag', updatedData, _selectedKeyId!);
      print("Update successful."); // 確認更新成功
      await _loadData(); // 重新載入資料
    } catch (e) {
      print("Update failed: $e"); // 捕獲並打印錯誤
    }
    _clearInputFields();

    _showMessage('成交成功！', Colors.green);
  }

  Future<void> _handleClose() async {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行平倉！', Colors.red);
      return;
    }

    final currentShares = _selectedRowData!['shares'] as int? ?? 0;
    final closingShares = int.tryParse(_dealSharesController.text) ?? 0;

    if (closingShares > currentShares) {
      _showMessage('平倉股數不可超過現有股數！', Colors.red);
      return;
    }

    final settledData = {..._selectedRowData!, 'closing_shares': closingShares};

    await dbHelper.insert('Options_Order_Settled', settledData);
    if (closingShares == currentShares) {
      await dbHelper.delete('Options_Order_Bag', _selectedKeyId!);
    } else {
      await dbHelper.update('Options_Order_Bag', {
        'shares': currentShares - closingShares,
      }, _selectedKeyId!);
    }

    await _loadData();
    _clearInputFields();
    _showMessage('平倉成功！', Colors.green);
  }

  Future<void> _handleUpdate() async {
    if (_selectedKeyId == null) {
      _showMessage('請選擇一筆資料進行修改！', Colors.red);
      return;
    }

    final updatedOrder = {
      'bank': _bankController.text,
      'symbol': _symbolController.text,
      'expiration': _expirationController.text,
      'strike': int.tryParse(_strikeController.text),
      'shares': int.tryParse(_sharesController.text),
      'order_premium': double.tryParse(_orderPremiumController.text),
      'order_date': _orderDateController.text,
    };

    await dbHelper.update('Options_Order_Bag', updatedOrder, _selectedKeyId!);
    await _loadData();
    _clearInputFields();
    _showMessage('修改成功！', Colors.green);
  }

  Future<void> _handleDelete() async {
    if (_selectedKeyId == null) {
      _showMessage('請選擇一筆資料進行刪除！', Colors.red);
      return;
    }

    await dbHelper.delete('Options_Order_Bag', _selectedKeyId!);
    await _loadData();
    _clearInputFields();
    _showMessage('刪除成功！', Colors.green);
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
    print("Input fields cleared."); // Trace: 確認輸入欄位已清空
  }


  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
    print("Panel visibility toggled: $_isPanelVisible"); // Trace 3
  }

  @override
  Widget build(BuildContext context) {
    print("Building UI..."); // Trace 4
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Column(
              children: [
                // 資料輸入區
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                            _buildInputField(
                                '到期日 (yyyy-mm-dd)', _expirationController),
                            _buildInputField('執行價', _strikeController),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('下單股數', _sharesController),
                            _buildInputField(
                                '下單權利金', _orderPremiumController),
                            _buildInputField(
                                '下單日 (yyyy-mm-dd)', _orderDateController),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInputField('成交股數', _dealSharesController),
                            _buildInputField(
                                '成交權利金', _dealPremiumController),
                            _buildInputField(
                                '成交日 (yyyy-mm-dd)', _dealDateController),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 資料列表
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSideButton('下單', Colors.lightBlue.shade100, () {
                    _handleAction('下單');
                  }),
                  const SizedBox(height: 6),
                  _buildSideButton('成交', Colors.lightBlue.shade200, () {
                    _handleAction('成交');
                  }),
                  const SizedBox(height: 6),
                  _buildSideButton('平倉', Colors.lightBlue.shade300, () {
                    _handleAction('平倉');
                  }),
                  const SizedBox(height: 6),
                  _buildSideButton('修改', Colors.lightBlue.shade400, () {
                    _handleAction('修改');
                  }),
                  const SizedBox(height: 6),
                  _buildSideButton('刪除', Colors.lightBlue.shade500, () {
                    _handleAction('刪除');
                  }),
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
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12),
            border: const OutlineInputBorder(),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_orderData.isEmpty) {
      print("No data to display in the table."); // 確認資料表為空
      return const Center(child: Text('訂單資料表內尚無資料！'));
    }

    print("Building data table with ${_orderData.length} rows."); // 確認資料行數
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
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
          print("Row data: $data"); // 打印每行資料
          return DataRow(
            selected: _selectedKeyId == data['key_id'],
            onSelectChanged: (selected) {
              if (selected != null && selected) {
                setState(() {
                  _selectedKeyId = data['key_id'];
                  _selectedRowData = data;
                  _fillInputFields(data);
                });
                print("Row selected: ${data['key_id']}"); // Trace 7
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
    print("Input fields filled with data: $data"); // Trace 8
  }

  void _showMessage(String message, Color color) {
    print("Showing message: $message"); // Trace 9
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
