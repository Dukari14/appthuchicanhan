import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:thuchicanhan/core/NavigationBar.dart';
import 'package:thuchicanhan/core/data_manager.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  print('Trạng thái ban đầu: ${SampleData.allTransactions.length} giao dịch.');

  await initializeTransactions('assets/data.json');

  print('Trạng thái sau khi tải: ${SampleData.allTransactions.length} giao dịch.');

  await initializeDateFormatting('vi_VN', null);

  // Thiết lập locale mặc định
  Intl.defaultLocale = 'vi_VN';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Thu Chi Cá Nhân',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(elevation: 0),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
    );
  }
}