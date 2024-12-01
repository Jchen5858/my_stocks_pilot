import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // 使用 'p' 作為別名
import 'package:uuid/uuid.dart';

class OptionsOrderPage extends StatefulWidget {
  const OptionsOrderPage({Key? key}) : super(key: key);

  @override
  _OptionsOrderPageState createState() => _OptionsOrderPageState();
}

class _OptionsOrderPageState extends State<OptionsOrderPage> {
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
  final uuid = Uuid();

  List<Map<String, dynamic>> _orderData = [];
  String? _selectedKeyId;
  Map<String, dynamic>? _selectedRowData;
  bool _isPanelVisible = false;


  @override
  void initState() {
    super.initState();
    _fetchOrderData();
  }

  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
    print("Panel visibility toggled: $_isPanelVisible");
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
    print("Input fields cleared.");
  }

  void _showMessage(String message, Color color) {
    print("Showing message: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchOrderData() async {
    try {
      final db = await DatabaseManager().database;

      if (db == null) {
        _showMessage("資料庫未初始化！", Colors.red);
        return;
      }

      // 檢查資料表是否存在
      final tableExists = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='Options_Order_Bag';",
      ));
      if (tableExists == null || tableExists == 0) {
        _showMessage("資料表 'Options_Order_Bag' 不存在！", Colors.red);
        return;
      }

      // 查詢資料
      final result = await db.query('Options_Order_Bag');
      setState(() {
        _orderData = result;
      });
    } catch (e) {
      _showMessage('初始化訂單資料失敗：$e', Colors.red);
    }
  }

  bool _isValidDate(String date) {
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null || parsedDate.toIso8601String().split('T').first != date) {
      return false;
    }
    return true;
  }

  bool _validateInputs(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      if (controller.text.isEmpty) {
        _showMessage('請填入所有必填欄位！', Colors.red);
        return false;
      }
    }

    // 驗證日期格式
    if (!_isValidDate(_expirationController.text) || !_isValidDate(_orderDateController.text)) {
      _showMessage('請輸入有效的日期 (yyyy-MM-dd 格式)！', Colors.red);
      return false;
    }

    // 驗證數值格式
    if (int.tryParse(_strikeController.text) == null) {
      _showMessage('執行價必須是整數！', Colors.red);
      return false;
    }
    if (int.tryParse(_sharesController.text) == null) {
      _showMessage('下單股數必須是整數！', Colors.red);
      return false;
    }
    if (double.tryParse(_orderPremiumController.text) == null) {
      _showMessage('下單權利金必須是數值！', Colors.red);
      return false;
    }

    return true;
  }

  void _handleOrder() async {
    if (!_validateInputs([
      _bankController,
      _symbolController,
      _expirationController,
      _strikeController,
      _sharesController,
      _orderPremiumController,
      _orderDateController,
    ])) {
      _showMessage('下單資料不可空白，請填入正確資料！', Colors.red);
      return;
    }

    final newOrder = {
      'key_id': uuid.v4(),
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

    try {
      final db = await DatabaseManager().database;

      // 檢查是否已存在相同鍵值
      final existingOrder = await db.query(
        'Options_Order_Bag',
        where: 'key_id = ?',
        whereArgs: [newOrder['key_id']],
      );

      if (existingOrder.isNotEmpty) {
        _showMessage('資料已存在，請檢查後重新輸入！', Colors.red);
        return;
      }

      await db.insert('Options_Order_Bag', newOrder);
      await _fetchOrderData(); // 更新資料
      _clearInputFields();
      _showMessage('下單成功！', Colors.green);
    } catch (e) {
      _showMessage('下單失敗：$e', Colors.red);
    }
  }

  void _handleDelete() async {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行刪除！', Colors.red);
      return;
    }

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('您確定要刪除此筆資料嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認'),
          ),
        ],
      ),
    );

    if (confirmDelete != true) {
      _showMessage('刪除操作已取消', Colors.orange);
      return; // 用戶取消刪除
    }

    try {
      final db = await DatabaseManager().database;
      await db.delete(
        'Options_Order_Bag',
        where: 'key_id = ?',
        whereArgs: [_selectedKeyId],
      );

      setState(() {
        _selectedRowData = null;
        _selectedKeyId = null;
      });

      await _fetchOrderData();
      _showMessage('刪除成功！', Colors.green);
    } catch (e) {
      _showMessage('刪除失敗：$e', Colors.red);
    }
  }


  void _handleAction(String action) async {
    switch (action) {
      case '下單':
        await _handleOrder();
        break;
      case '成交':
        print("Handle 成交 action triggered.");
        break;
      case '平倉':
        print("Handle 平倉 action triggered.");
        break;
      case '修改':
        print("Handle 修改 action triggered.");
        break;
      case '刪除':
        print("Handle 刪除 action triggered.");
        break;
    }
  }

  Widget _buildInputField(String label, TextEditingController controller, {TextInputType inputType = TextInputType.text}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          ),
        ),
      ),
    );
  }


  Widget _buildSideButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildDataTable() {
    if (_orderData.isEmpty) {
      return const Center(child: Text('訂單資料表內尚無資料！'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
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
            selected: _selectedKeyId == data['key_id'],
            onSelectChanged: (selected) {
              if (selected != null && selected) {
                setState(() {
                  _selectedKeyId = data['key_id'];
                  _selectedRowData = data;
                  _fillInputFields(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇權訂單作業'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 輸入區
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildInputField('銀行別', _bankController),
                        _buildInputField('股票代碼', _symbolController),
                      ],
                    ),
                    Row(
                      children: [
                        _buildInputField('到期日 (yyyy-mm-dd)', _expirationController),
                        _buildInputField('執行價', _strikeController),
                      ],
                    ),
                    Row(
                      children: [
                        _buildInputField('下單股數', _sharesController),
                        _buildInputField('下單權利金', _orderPremiumController),
                        _buildInputField('下單日 (yyyy-mm-dd)', _orderDateController),
                      ],
                    ),
                  ],
                ),
              ),
              // 資料列表
              Expanded(child: _buildDataTable()),
            ],
          ),
          // 側邊按鈕
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
                  _buildSideButton('下單', Colors.lightBlue.shade100, () => _handleAction('下單')),
                  const SizedBox(height: 6),
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
    print("Input fields filled with data: $data");
  }
}
