import 'package:flutter/material.dart';
import 'package:my_stocks_pilot/database/database_manager.dart';

class OptionsOrderPage extends StatefulWidget {
  const OptionsOrderPage({Key? key}) : super(key: key);

  @override
  _OptionsOrderPageState createState() => _OptionsOrderPageState();
}

class _OrderDataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final Function(Map<String, dynamic>) onRowSelected;
  final String? selectedKeyId;

  _OrderDataSource(this.data, this.onRowSelected, this.selectedKeyId);

  @override
  DataRow getRow(int index) {
    final row = data[index];
    final rowKeyId = row['key_id']?.toString();
    final isSelected = rowKeyId != null && rowKeyId == selectedKeyId;

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        if (selected != null && selected) {
          onRowSelected(row);
        }
      },
      cells: [
        DataCell(Text(row['bank'] ?? '')),
        DataCell(Text(row['symbol'] ?? '')),
        DataCell(Text(row['expiration'] ?? '')),
        DataCell(Text(row['strike']?.toString() ?? '')),
        DataCell(Text(row['shares']?.toString() ?? '')),
        DataCell(Text(row['order_premium']?.toString() ?? '')),
        DataCell(Text(row['order_date'] ?? '')),
        DataCell(Text(row['deal_shares']?.toString() ?? '')),
        DataCell(Text(row['deal_premium']?.toString() ?? '')),
        DataCell(Text(row['deal_date'] ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => selectedKeyId == null ? 0 : 1; // 正確計算選中行數
}

class _OptionsOrderPageState extends State<OptionsOrderPage> {
  final DatabaseManager _dbManager = DatabaseManager();

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

  String? _selectedKeyId; // 選中的訂單 ID; 初始為 null
  Map<String, dynamic>? _selectedRowData; // 選中的資料列
  List<Map<String, dynamic>> _orderData = []; // 訂單數據列表

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      // 確認資料表是否存在
      final tables = await _dbManager.getTableNames();
      if (!tables.contains('Options_Order_Bag')) {
        throw Exception('資料表 Options_Order_Bag 不存在！');
      }

      // 讀取資料表內容
      final data = await _dbManager.queryTable('Options_Order_Bag');
      setState(() {
        _orderData = data; // 正確更新狀態變數
      });
    } catch (e) {
      _showMessage('初始化資料失敗：$e', Colors.red);
    }
  }


  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
  }

  bool _validateInput() {
    if (_bankController.text.isEmpty ||
        _symbolController.text.isEmpty ||
        _expirationController.text.isEmpty ||
        _strikeController.text.isEmpty ||
        _sharesController.text.isEmpty ||
        _orderPremiumController.text.isEmpty ||
        _orderDateController.text.isEmpty) {
      _showMessage('所有欄位不可空白，請填寫正確資料！', Colors.red);
      return false;
    }

    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!datePattern.hasMatch(_expirationController.text) ||
        !datePattern.hasMatch(_orderDateController.text)) {
      _showMessage('日期格式錯誤，應為 yyyy-mm-dd！', Colors.red);
      return false;
    }

    return true;
  }

  Future<void> _reloadData() async {
    try {
      final data = await _dbManager.queryTable('Options_Order_Bag');
      setState(() {
        _orderData = data.where((row) => row['key_id'] != null).toList(); // 確保包含所有有效資料
      });
      print('載入資料筆數：${_orderData.length}');
    } catch (e) {
      _showMessage('資料重載失敗：$e', Colors.red);
    }
  }

  void _testDefaults() {
    final today = DateTime.now();
    final todayFormatted = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    print("當天日期：$todayFormatted");
    print("成交股數預設：${_selectedRowData?['shares'] ?? '無資料'}");
    print("成交權利金預設：${_selectedRowData?['order_premium'] ?? '無資料'}");
  }

  void _onRowSelected(Map<String, dynamic> row) {
    setState(() {
      _selectedKeyId = row['key_id']?.toString(); // 確保是字串
      _selectedRowData = Map<String, dynamic>.from(row); // 創建可變副本
      _fillInputFields(_selectedRowData!);
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
                      child: _buildDataTable(), // 調用資料表組件
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
            top: 220,
            bottom: 180,
            child: Container(
              width: 80,
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
                  const SizedBox(height: 4), // 調整按鈕之間的上下間距
                  _buildSideButton('成交', Colors.lightBlue.shade200, () =>
                      _handleAction('成交')),
                  const SizedBox(height: 4),
                  _buildSideButton('平倉', Colors.lightBlue.shade300, () =>
                      _handleAction('平倉')),
                  const SizedBox(height: 4),
                  _buildSideButton('修改', Colors.lightBlue.shade400, () =>
                      _handleAction('修改')),
                  const SizedBox(height: 4),
                  _buildSideButton('刪除', Colors.lightBlue.shade500, () =>
                      _handleAction('刪除')),
                ],
              ),
            ),
          ),

          // 觸發按鈕
          Positioned(
            left: 8, // 將按鈕移到左側
            top: 260, // 根據需要調整垂直位置
            child: GestureDetector(
              onTap: _togglePanel,
              child: Container(
                width: 30, // 按鈕寬度
                height: 50, // 按鈕高度
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8), // 調整為右側圓角
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      '按鈕',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0), // 調整邊距更靠左
      child: PaginatedDataTable(
        header: const Text(
          '訂單資料',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        showCheckboxColumn: false, // 隱藏預設的選中列
        columnSpacing: 4.0, // 減少欄位之間的間距
        dataRowHeight: 40, // 行距
        headingRowHeight: 40, // 表頭高度
        rowsPerPage: 5, // 每頁行數
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
        source: _OrderDataSource(_orderData, _onRowSelected, _selectedKeyId),
      ),
    );
  }

  Widget _buildSideButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // 調整按鍵內部邊距
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // 縮小文字
        minimumSize: const Size(60, 30), // 調整按鍵大小
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  void _fillInputFields(Map<String, dynamic> data) {
    final today = DateTime.now();
    final todayFormatted =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    print('選中資料：$data');

    _bankController.text = data['bank'] ?? '';
    _symbolController.text = data['symbol'] ?? '';
    _expirationController.text = data['expiration'] ?? '';
    _strikeController.text = data['strike']?.toString() ?? '';
    _sharesController.text = data['shares']?.toString() ?? '';
    _orderPremiumController.text = data['order_premium']?.toString() ?? '';

    // 下單日檢查
    if (data['order_date'] == null || data['order_date'].isEmpty) {
      print('下單日為空，填入當天日期：$todayFormatted');
      _orderDateController.text = todayFormatted;
    } else {
      _orderDateController.text = data['order_date'];
    }

    // 成交欄位僅打印，不填充
    print('成交欄位檢查：');
    print('deal_shares：${data['deal_shares']}');
    print('deal_premium：${data['deal_premium']}');
    print('deal_date：${data['deal_date']}');
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

  void _handleOrder() async {
    if (!_validateInput()) return;

    final today = DateTime.now();
    final todayFormatted = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final newOrder = {
      'key_id': 'ORD-${DateTime.now().toIso8601String()}',
      'bank': _bankController.text,
      'symbol': _symbolController.text,
      'expiration': _expirationController.text,
      'strike': int.tryParse(_strikeController.text) ?? 0,
      'shares': int.tryParse(_sharesController.text) ?? 0,
      'order_premium': double.tryParse(_orderPremiumController.text) ?? 0.0,
      'order_date': _orderDateController.text.isEmpty ? todayFormatted : _orderDateController.text,
      'deal_shares': null,
      'deal_premium': null,
      'deal_date': null,
    };

    try {
      final db = await _dbManager.database;
      await db.insert('Options_Order_Bag', newOrder);

      await _reloadData(); // 確保即時刷新所有資料
      _clearInputFields();
      _showMessage('下單成功！', Colors.green);
    } catch (e) {
      _showMessage('下單失敗：$e', Colors.red);
    }
  }

  void _handleUpdate() async {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行修改！', Colors.red);
      return;
    }

    final updatedData = {
      'bank': _bankController.text,
      'symbol': _symbolController.text,
      'expiration': _expirationController.text,
      'strike': int.tryParse(_strikeController.text),
      'shares': int.tryParse(_sharesController.text),
      'order_premium': double.tryParse(_orderPremiumController.text),
      'order_date': _orderDateController.text,
    };

    try {
      final db = await _dbManager.database;
      await db.update(
        'Options_Order_Bag',
        updatedData,
        where: 'key_id = ?',
        whereArgs: [_selectedKeyId],
      );

      await _reloadData(); // 確保即時刷新所有資料
      _clearInputFields();
      _showMessage('修改成功！', Colors.green);
    } catch (e) {
      _showMessage('修改失敗：$e', Colors.red);
    }
  }

  Future<void> _handleFullClose() async {
    final db = await _dbManager.database;

    await db.transaction((txn) async {
      print('全部平倉，刪除 Options_Order_Bag 資料：key_id = $_selectedKeyId');

      // 插入平倉記錄
      final closedData = {
        'key_id': 'CLOSE-${DateTime.now().toIso8601String()}',
        'options_act': _selectedRowData!['options_act'],
        'options_type': _selectedRowData!['options_type'],
        'bank': _selectedRowData!['bank'],
        'symbol': _selectedRowData!['symbol'],
        'expiration': _selectedRowData!['expiration'],
        'strike': _selectedRowData!['strike'],
        'shares': _selectedRowData!['shares'],
        'order_premium': _selectedRowData!['order_premium'],
        'order_date': _selectedRowData!['order_date'],
        'deal_date': _selectedRowData!['deal_date'],
        'deal_premium': _selectedRowData!['deal_premium'],
        'deal_shares': _selectedRowData!['deal_shares'],
        'closing_date': DateTime.now().toIso8601String(),
      };
      print('即將插入 Options_Order_Closed 資料：$closedData');
      await txn.insert('Options_Order_Closed', closedData);

      // 刪除 Options_Order_Bag
      await txn.delete('Options_Order_Bag', where: 'key_id = ?', whereArgs: [_selectedKeyId]);
      _orderData.removeWhere((order) => order['key_id'] == _selectedKeyId);
    });
  }

  Future<void> handlePartialClose(int closingShares, Map<String, dynamic> selectedRowData) async {
    try {
      final dbManager = DatabaseManager();

      await dbManager.executeTransaction((txn) async {
        print('開始部分平倉，平倉股數：$closingShares');

        final remainingShares = selectedRowData['shares'] - closingShares;
        print('部分平倉後剩餘股數：$remainingShares');

        // 插入平倉記錄
        final closedData = {
          'key_id': 'CLOSE-${DateTime.now().toIso8601String()}',
          'options_act': selectedRowData['options_act'],
          'options_type': selectedRowData['options_type'],
          'bank': selectedRowData['bank'],
          'symbol': selectedRowData['symbol'],
          'expiration': selectedRowData['expiration'],
          'strike': selectedRowData['strike'],
          'shares': closingShares,
          'order_premium': selectedRowData['order_premium'],
          'order_date': selectedRowData['order_date'],
          'closing_date': DateTime.now().toIso8601String(),
        };
        print('插入 Options_Order_Closed 資料：$closedData');
        await txn.insert('Options_Order_Closed', closedData);

        // 更新剩餘股數
        print('更新 Options_Order_Bag 剩餘股數...');
        await txn.update(
          'Options_Order_Bag',
          {'shares': remainingShares},
          where: 'key_id = ?',
          whereArgs: [selectedRowData['key_id']],
        );
      });

      print('部分平倉成功！');
    } catch (e) {
      print('部分平倉失敗，錯誤信息：$e');
      rethrow;
    }
  }

  void _handleClose() async {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行平倉！', Colors.red);
      return;
    }

    // 檢查 order_date, order_premium, shares 是否有值
    final orderDate = _selectedRowData!['order_date'];
    final orderPremium = _selectedRowData!['order_premium'];
    final orderShares = _selectedRowData!['shares'];

    if (orderDate == null || orderDate.isEmpty ||
        orderPremium == null ||
        orderShares == null || orderShares <= 0) {
      _showMessage('未成交訂單不得平倉!!!', Colors.red);
      print('平倉失敗：未成交訂單，無法進行平倉操作！');
      return;
    }

    final currentShares = orderShares as int;

    print('開始平倉操作，選中資料：$_selectedRowData');

    // 顯示平倉股數輸入對話框
    final closingShares = await showDialog<int>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentShares.toString());
        return AlertDialog(
          title: const Text('平倉股數'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '輸入平倉股數'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(context, int.tryParse(controller.text) ?? 0),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );

    // 驗證平倉股數
    if (closingShares == null || closingShares <= 0 || closingShares > currentShares) {
      print('平倉失敗，無效的平倉股數：$closingShares');
      _showMessage('平倉股數無效！', Colors.red);
      return;
    }

    try {
      if (closingShares == currentShares) {
        // 全部平倉邏輯
        print('執行全部平倉...');
        await _handleFullClose();
      } else {
        // 部分平倉邏輯
        print('執行部分平倉...');
        await handlePartialClose(closingShares, _selectedRowData!);
      }

      await _reloadData();
      _clearInputFields();
      _showMessage('平倉成功！', Colors.green);
    } catch (e) {
      print('平倉失敗，錯誤信息：$e');
      _showMessage('平倉失敗：$e', Colors.red);
    }
  }


  void _handleDeal() async {
    if (_selectedRowData == null) {
      _showMessage('請選擇一筆資料進行成交！', Colors.red);
      return;
    }

    // 初始化資料，必要時填充空欄位
    final dealSharesBefore = _selectedRowData?['deal_shares'];
    final dealPremiumBefore = _selectedRowData?['deal_premium'];
    final dealDateBefore = _selectedRowData?['deal_date'];

    final dealShares = dealSharesBefore ?? _selectedRowData?['shares'] ?? 0;
    final dealPremium = dealPremiumBefore ?? _selectedRowData?['order_premium'] ?? 0.0;
    final dealDate = (dealDateBefore == null || dealDateBefore.isEmpty)
        ? "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
        : dealDateBefore;

    // 打印填充前後的資料
    print('成交資料填充：');
    print('deal_shares（前）：$dealSharesBefore -> （後）：$dealShares');
    print('deal_premium（前）：$dealPremiumBefore -> （後）：$dealPremium');
    print('deal_date（前）：$dealDateBefore -> （後）：$dealDate');

    if (dealShares <= 0 || dealPremium <= 0.0) {
      _showMessage('成交資料不正確！', Colors.red);
      return;
    }

    try {
      final db = await _dbManager.database;
      await db.update(
        'Options_Order_Bag',
        {
          'deal_shares': dealShares,
          'deal_premium': dealPremium,
          'deal_date': dealDate,
        },
        where: 'key_id = ?',
        whereArgs: [_selectedKeyId],
      );

      // 更新本地資料
      setState(() {
        _selectedRowData!['deal_shares'] = dealShares;
        _selectedRowData!['deal_premium'] = dealPremium;
        _selectedRowData!['deal_date'] = dealDate;
      });

      await _reloadData();
      _showMessage('成交成功！', Colors.green);
    } catch (e) {
      _showMessage('成交失敗：$e', Colors.red);
    }
  }

  void _handleDelete() async {
    if (_selectedRowData == null || _selectedKeyId == null) {
      _showMessage('請選擇一筆資料進行刪除！', Colors.red);
      return;
    }

    final confirm = await showDialog<bool>(
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

    if (confirm == true) {
      try {
        final db = await _dbManager.database;
        final deleted = await db.delete(
          'Options_Order_Bag',
          where: 'key_id = ?',
          whereArgs: [_selectedKeyId],
        );

        if (deleted > 0) {
          await _reloadData(); // 保證即時刷新
          _showMessage('刪除成功！', Colors.green);
        } else {
          _showMessage('刪除失敗：找不到資料！', Colors.red);
        }
      } catch (e) {
        _showMessage('刪除失敗：$e', Colors.red);
      }
    }
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
      _selectedKeyId = null; // 清空選中狀態
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