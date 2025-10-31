import 'package:flutter/material.dart';

import 'package:thuchicanhan/screens/dashboard.dart';
import 'package:thuchicanhan/screens/additem.dart';
import 'package:thuchicanhan/screens/statistics_table.dart';
import 'package:thuchicanhan/screens/listitem.dart';
import 'package:thuchicanhan/screens/settings.dart';


import 'package:thuchicanhan/core/data_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  // Dữ liệu giao dịch chính được lưu trữ ở đây
  List<Transaction> _transactions = List.from(SampleData.allTransactions);

  // Cập nhật lại danh sách gốc (dùng cho ListTransactionPage)
  void _updateTransactions(List<Transaction> newTransactions) {
    setState(() {
      _transactions = newTransactions;
    });
  }

  // Phương thức thêm giao dịch (dùng cho AddTransactionScreen)
  void _addTransaction(Transaction transaction) {
    setState(() {
      // Thêm vào đầu danh sách (để hiển thị ngay trong Dashboard và List)
      _transactions.insert(0, transaction);
      // Lưu lại dữ liệu mới vào file cục bộ sau khi thêm
      DataManager.saveData(_transactions);
    });
    // Trở về màn hình Dashboard sau khi thêm
    _onItemTapped(0);
  }

  void _handleDataImported(List<Transaction>? newTransactions) {
    if (newTransactions != null) {
      setState(() {
        _transactions = newTransactions;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Danh sách các màn hình
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Khởi tạo _widgetOptions trong initState
    _widgetOptions = _createWidgetOptions();
  }
  // Tạo danh sách widget với dữ liệu hiện tại
  List<Widget> _createWidgetOptions() {
    return <Widget>[
      // 0: Dashboard
      DashboardPage(transactions: _transactions),
      // 1: Danh sách Thu Chi
      TransactionListPage(
        transactions: _transactions,
        onUpdateTransactions: _updateTransactions,
      ),
      // 2: Thêm Giao Dịch
      AddTransactionScreen(onAddTransaction: _addTransaction),
      // 3: Báo Cáo
      ReportScreen(transactions: _transactions),
      SettingsPage(
        currentTransactions: _transactions,
        onDataImported: _handleDataImported, // Truyền callback
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Cần cập nhật lại DashboardPage và ReportScreen khi _transactions thay đổi
    _widgetOptions = _createWidgetOptions();

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Giao dịch'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Thêm'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Giữ màu sắc khi có 4 items
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}