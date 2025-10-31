import 'package:flutter/material.dart';
import 'package:thuchicanhan/core/data_manager.dart';

class SettingsPage extends StatefulWidget {
  final List<Transaction> currentTransactions;
  // Callback để MainScreen cập nhật lại dữ liệu sau khi import
  final Function(List<Transaction>?) onDataImported;

  const SettingsPage({
    super.key,
    required this.currentTransactions,
    required this.onDataImported,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Hàm xử lý Xuất dữ liệu
  Future<void> _handleExport() async {
    _showSnackbar('Đang mở hộp thoại chọn vị trí...', isError: false);

    // Gọi hàm mới: exportDataToUserChosenLocation
    final result = await DataManager.exportDataToUserChosenLocation(
        widget.currentTransactions);

    if (result != null && result.startsWith('LỖI CẤU HÌNH')) {
      // Thông báo rõ ràng về lỗi UnimplementedError trên Android
      _showSnackbar(result, isError: true);
    } else if (result != null && result.isNotEmpty) {
      // Xuất thành công
      _showSnackbar('Xuất thành công! File lưu tại: $result', isError: false);
    } else {
      // Bị hủy
      _showSnackbar('Xuất file bị hủy hoặc hoàn tất.', isError: false);
    }
  }

  // Hàm xử lý Nhập dữ liệu
  Future<void> _handleImport() async {
    _showSnackbar('Đang mở hộp thoại chọn file...', isError: false);

    // Gọi hàm mới sử dụng file_picker
    final newTransactions = await DataManager.importDataFromUserChosenFile();

    if (newTransactions != null) {
      // Gọi callback để cập nhật danh sách giao dịch ở MainScreen
      widget.onDataImported(newTransactions);
      _showSnackbar('Nhập dữ liệu thành công từ file đã chọn!', isError: false);
    } else {
      _showSnackbar(
          'Nhập Dữ liệu bị hủy hoặc gặp lỗi khi đọc file. Vui lòng thử lại.',
          isError: true
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Quản lý Dữ liệu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Divider(),

            // Nút Xuất dữ liệu
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Xuất dữ liệu'),
              subtitle: const Text('Lưu file JSON vào thư mục.'),
              onTap: _handleExport,
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(indent: 16, endIndent: 16),

            // Nút Nhập dữ liệu
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.orange),
              title: const Text('Nhập dữ liệu'),
              subtitle: const Text(
                  'Yêu cầu file "import.json" trong thư mục của ứng dụng.'),
              onTap: _handleImport,
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(),

            // HƯỚNG DẪN QUAN TRỌNG
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "LƯU Ý QUAN TRỌNG ĐỐI VỚI ANDROID:\n",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    TextSpan(
                      text: "File sau khi được xuất sẽ được lưu vào đường dẫn:\n",
                    ),
                    TextSpan(
                      text: "Android/data/com.thuchi.thuchicanhan/file/DataExported",
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 14),
              ),
            )
          ],
        ),
      ),
    );
  }
}