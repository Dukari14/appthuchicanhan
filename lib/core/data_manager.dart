import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

// Phần lớp chính của ứng dụng
enum TransactionType { income, expense }

class Transaction {
  String name;
  String category;
  DateTime date;
  double amount;
  final TransactionType type;

  Transaction({
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.type,
  });

  Transaction copyWith({
    String? name,
    String? category,
    DateTime? date,
    double? amount,
  }) {
    return Transaction(
      name: name ?? this.name,
      category: category ?? this.category,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: this.type,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    TransactionType getType(String typeString) {
      if (typeString == 'income') return TransactionType.income;
      if (typeString == 'expense') return TransactionType.expense;
      throw ArgumentError('Invalid TransactionType: $typeString');
    }

    return Transaction(
      name: json['name'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String), // Chuyển đổi chuỗi ngày ISO 8601 thành đối tượng DateTime
      amount: json['amount'] as double,
      type: getType(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'date': date.toIso8601String(), // Đảm bảo DateTime được chuyển thành chuỗi ISO 8601
      'amount': amount,
      'type': type.toString().split('.').last, // Chuyển enum thành chuỗi ('income'/'expense')
    };
  }
}

// Dữ liệu của cả ứng dụng
class SampleData {
  static List<Transaction> allTransactions = []; // Data sẽ lấy dữ liệu từ file json
}

const String _localFileName = 'data.json'; // File dùng cho việc lưu và lấy dữ liệu

// Hàm Lấy đối tượng File cục bộ
Future<File> _getLocalFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/$_localFileName');
}

// Hàm tải từ Assets và Lưu thành File Cục bộ nếu File Cục bộ chưa tồn tại
Future<void> _loadFromAssetsAndSave(String assetPath, File localFile) async {
  print('Đang tải dữ liệu mẫu từ Assets và tạo file cục bộ...');
  try {
    // Đọc dữ liệu mẫu từ Assets
    final String jsonString = await rootBundle.loadString(assetPath);
    final dynamic jsonDecoded = jsonDecode(jsonString);

    if (jsonDecoded is List) {
      SampleData.allTransactions = jsonDecoded
          .cast<Map<String, dynamic>>()
          .map((jsonMap) => Transaction.fromJson(jsonMap))
          .toList();

      // Lưu lại dữ liệu mẫu vào file cục bộ (TẠO FILE NẾU CHƯA TỒN TẠI)
      await saveTransactionsToJsonFile(SampleData.allTransactions, _localFileName);

      print('Đã tải từ Assets và tạo file cục bộ thành công: ${localFile.path}');
    } else {
      print('Lỗi: Dữ liệu JSON trong Assets không phải là mảng.');
    }
  } catch (e) {
    print('Lỗi nghiêm trọng khi tải từ Assets: $e');
    // Nếu cả assets cũng lỗi, List sẽ vẫn là rỗng
    SampleData.allTransactions = [];
  }
}

// HÀM KHỞI TẠO DỮ LIỆU CHÍNH
Future<void> initializeTransactions(String assetPath) async {
  print('Bắt đầu khởi tạo dữ liệu cho ứng dụng...');
  final localFile = await _getLocalFile(); // Lấy File object cục bộ

  if (await localFile.exists()) {
    // ƯU TIÊN LOCAL: Đọc từ file cục bộ nếu đã tồn tại
    print('Đã tìm thấy file cục bộ. Đang tải dữ liệu từ ${localFile.path}');
    try {
      final String jsonString = await localFile.readAsString();
      final dynamic jsonDecoded = jsonDecode(jsonString);

      if (jsonDecoded is List) {
        SampleData.allTransactions = jsonDecoded
            .cast<Map<String, dynamic>>()
            .map((jsonMap) => Transaction.fromJson(jsonMap))
            .toList();

        print('Tải cục bộ thành công ${SampleData.allTransactions.length} giao dịch.');
      } else {
        print('Lỗi: Dữ liệu JSON cục bộ bị hỏng. Đang tạo lại file từ Assets.');
        // Nếu file cục bộ bị hỏng, tạo lại file từ Assets
        await _loadFromAssetsAndSave(assetPath, localFile);
      }
    } catch (e) {
      print('Lỗi khi đọc file cục bộ: $e. Đang tạo lại file từ Assets.');
      // Nếu có lỗi I/O hoặc lỗi giải mã, tạo lại file từ Assets
      await _loadFromAssetsAndSave(assetPath, localFile);
    }
  } else {
    // TẠO FILE MẶC ĐỊNH: Nếu tệp cục bộ chưa tồn tại, tải từ Assets và lưu lại
    print('File cục bộ chưa tồn tại. Đang tạo file mặc định từ Assets.');
    await _loadFromAssetsAndSave(assetPath, localFile);
  }
}

Future<void> saveTransactionsToJsonFile(List<Transaction> transactions, String filename) async {
  // Chuyển đổi List<Transaction> thành List<Map<String, dynamic>>
  final List<Map<String, dynamic>> transactionMaps =
  transactions.map((tx) => tx.toJson()).toList();

  // Mã hóa List<Map> thành chuỗi JSON
  // Sử dụng JsonEncoder.withIndent để chuỗi JSON dễ đọc (pretty print)
  final JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final String jsonString = encoder.convert(transactionMaps);

  try {
    // Lấy thư mục tài liệu cục bộ của ứng dụng (nơi an toàn để lưu trữ dữ liệu)
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');

    // Ghi chuỗi JSON vào file
    await file.writeAsString(jsonString);

    print('Dữ liệu đã được lưu thành công vào file: ${file.path}');
  } catch (e) {
    print('Lỗi khi lưu file JSON: $e');
  }
}

// Class dùng cho việc xuất và nạp data
class DataManager {
  static const String _fileName = 'data.json';

  // Lấy đường dẫn cục bộ (nơi ứng dụng lưu file data.json)
  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Hàm chuyển đổi danh sách giao dịch sang JSON string
  static String _transactionsToJson(List<Transaction> transactions) {
    List<Map<String, dynamic>> jsonList =
    transactions.map((t) => t.toJson()).toList();
    // Sử dụng '  ' cho định dạng dễ đọc (pretty print)
    return JsonEncoder.withIndent('  ').convert(jsonList);
  }

  // Ghi dữ liệu vào file cục bộ (data.json)
  static Future<File> saveData(List<Transaction> transactions) async {
    final jsonString = _transactionsToJson(transactions);
    final file = await _localFile;
    return file.writeAsString(jsonString);
  }

  // Đọc dữ liệu từ file cục bộ (dùng khi khởi động)
  static Future<List<Transaction>> readData() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => Transaction.fromJson(e)).toList();
    } catch (e) {
      print('Lỗi khi đọc file cục bộ: $e');
      return [];
    }
  }

  // HÀM XUẤT DỮ LIỆU VÀO THƯ MỤC DOWNLOADS (Android Public Storage)
  static Future<String?> exportDataToUserChosenLocation(List<Transaction> transactions) async {
    const String fileName = 'data_exported.json';
    final jsonString = _transactionsToJson(transactions);
    final bytes = utf8.encode(jsonString);

    if (Platform.isAndroid) {
      try {
        final externalDir = await getExternalStorageDirectory();

        if (externalDir == null) {
          return 'Lỗi: Không tìm thấy bộ nhớ ngoài.';
        }

        // Tạo thư mục "Download" (hoặc tên bất kỳ) trong thư mục gốc
        final downloadPath = '${externalDir.path}/DataExported';
        final Directory downloadDir = Directory(downloadPath);
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        final File exportFile = File('$downloadPath/$fileName');
        await exportFile.writeAsBytes(bytes, flush: true);

        // Trả về đường dẫn
        return exportFile.path;

      } on FileSystemException {
        return 'Lỗi Quyền: Cần quyền WRITE_EXTERNAL_STORAGE. Đã thêm vào AndroidManifest chưa?';
      } catch (e) {
        print('Lỗi xuất file Android: $e');
        // Tiếp tục Fallback (chuyển sang file_picker.saveFile())
      }
    }

    // Fallback: Sử dụng file_picker.saveFile() cho iOS, Desktop
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Chọn nơi lưu file data.json',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes, flush: true);
        return outputFile;
      }

      return null;

    } on UnimplementedError {
      return 'Lỗi: Chức năng Save File không được hỗ trợ trên nền tảng này.';
    } catch (e) {
      return 'Lỗi xuất file chung: $e';
    }
  }

  // HÀM NẠP DỮ LIỆU TỪ FILE JSON NGOÀI
  static Future<List<Transaction>?> importDataFromUserChosenFile() async {
    try {
      // Mở hộp thoại chọn file (chỉ cho phép chọn file .json)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        // Đọc nội dung file JSON ngoài
        final jsonString = await file.readAsString();
        final List<dynamic> jsonMap = json.decode(jsonString);
        final newTransactions = jsonMap.map((e) => Transaction.fromJson(e)).toList();

        // Ghi dữ liệu mới vào file cục bộ data.json (ghi đè)
        await saveData(newTransactions);

        return newTransactions;
      } else {
        // Người dùng đã hủy hoặc không chọn file
        return null;
      }
    } catch (e) {
      print('Lỗi nhập dữ liệu từ file chọn: $e');
      return null;
    }
  }
}

// Lớp Dữ liệu cho Dashboard
class TransactionItem {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  TransactionItem(this.title, this.amount, this.icon, this.color);
}

// Các Hàm Tiện ích

// Định dạng số tiền
String formatNumber(double number) {
  final formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '',
    decimalDigits: 0,
  );
  return formatter.format(number).trim();
}

// Hàm tính toán tổng hợp (Cho Dashboard)
Map<String, double> calculateSummary(List<Transaction> transactions) {
  double totalIncome = 0;
  double totalExpense = 0;

  final now = DateTime.now(); // Lấy thời gian hiện tại theo thời gian thực
  final currentMonth = now.month;
  final currentYear = now.year;

  for (var t in transactions) {
    // Chỉ tính các giao dịch trong tháng/năm hiện tại
    if (t.date.month == currentMonth && t.date.year == currentYear) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
  }

  return {
    'thunhap': totalIncome,
    'chitieu': totalExpense,
    'tongthunhap': totalIncome - totalExpense, // Tổng số dư tháng này
  };
}

// Tạo danh sách giao dịch gần đây cho Dashboard
List<TransactionItem> getRecentTransactions(List<Transaction> transactions) {
  // Sắp xếp theo ngày mới nhất lên trước
  final sorted = transactions.toList()..sort((a, b) => b.date.compareTo(a.date));

  // Chỉ lấy tối đa 5 giao dịch gần nhất
  final recent = sorted.take(5);

  return recent.map((t) {
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? Colors.blue.shade700 : Colors.red.shade700;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    final sign = isIncome ? '+' : '-';
    return TransactionItem(
      t.name,
      '$sign ${formatNumber(t.amount)}',
      icon,
      color,
    );
  }).toList();
}