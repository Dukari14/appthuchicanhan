import 'package:flutter/material.dart';
import 'package:thuchicanhan/core/data_manager.dart';

class AddTransactionScreen extends StatefulWidget {
  // Thêm callback để gửi giao dịch mới về MainScreen
  final Function(Transaction) onAddTransaction;

  const AddTransactionScreen({super.key, required this.onAddTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Danh mục cố định cho từng loại
  final Map<String, List<String>> _allCategories = {
    'Chi tiêu': ['Nhà cửa', 'Ăn uống', 'Giải trí', 'Đi lại', 'Khác'],
    'Thu nhập': ['Lương', 'Nguồn thu nhập khác'],
  };

  // Trạng thái của form
  String _transactionType = 'Chi tiêu'; // Mặc định là Chi tiêu
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh mục mặc định
    _selectedCategory = _allCategories[_transactionType]![0];
  }

  // Hàm tự định dạng ngày
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Hàm hiển thị Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Chọn Ngày Giao Dịch',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Hàm xử lý khi người dùng nhấn nút Thêm
  void _submitData() async {
    // Kiểm tra dữ liệu bắt buộc
    if (_nameController.text.isEmpty || _amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')),
      );
      return;
    }

    final String name = _nameController.text;
    final double? amount = double.tryParse(_amountController.text);
    final String category = _selectedCategory!;
    final TransactionType type =
    _transactionType == 'Thu nhập' ? TransactionType.income : TransactionType.expense;

    // Kiểm tra số tiền hợp lệ
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền không hợp lệ!')),
      );
      return;
    }

    // Tạo Transaction object
    final newTransaction = Transaction(
      name: name,
      category: category,
      date: _selectedDate,
      amount: amount,
      type: type,
    );

    // GỌI CALLBACK ĐỂ GỬI OBJECT VỀ MAINSCREEN VÀ SAVE DATA
    widget.onAddTransaction(newTransaction);
    SampleData.allTransactions.add(newTransaction);

    // ĐOẠN CODE LƯU DỮ LIỆU
    try {
      await saveTransactionsToJsonFile(
        SampleData.allTransactions,
        'data.json',
      );

      // KIỂM TRA mounted TRƯỚC KHI TƯƠNG TÁC VỚI CONTEXT/UI
      if (!mounted) return;

      // Thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Đã thêm giao dịch **${_transactionType}**: $name - ${amount} VNĐ')),
      );

      // Reset form
      _nameController.clear();
      _amountController.clear();
      setState(() {
        _transactionType = 'Chi tiêu';
        _selectedCategory = _allCategories[_transactionType]![0];
        _selectedDate = DateTime.now();
      });

    } catch (e) {
      print('Lỗi khi lưu dữ liệu JSON: $e');
      // KIỂM TRA mounted TRƯỚC KHI TƯƠNG TÁC VỚI CONTEXT/UI
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không thể lưu dữ liệu!')),
      );
    }
  }

  // Hàm xử lý khi thay đổi loại giao dịch (Chi tiêu/Thu nhập)
  void _onTypeChanged(String? newType) {
    if (newType != null) {
      setState(() {
        _transactionType = newType;
        // Đặt lại danh mục đã chọn thành mục đầu tiên của danh mục mới
        _selectedCategory = _allCategories[newType]![0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách danh mục hiện tại dựa trên loại giao dịch đã chọn
    final List<String> currentCategories = _allCategories[_transactionType] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Giao Dịch Thu Chi'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Loại Giao Dịch (Thu nhập / Chi tiêu)
            const Text(
              'Loại Giao Dịch:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Thu nhập'),
                    value: 'Thu nhập',
                    groupValue: _transactionType,
                    onChanged: _onTypeChanged,
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Chi tiêu'),
                    value: 'Chi tiêu',
                    groupValue: _transactionType,
                    onChanged: _onTypeChanged,
                    activeColor: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Danh mục (Thay đổi theo Loại Giao Dịch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Chọn Danh mục'),
                  value: _selectedCategory,
                  items: currentCategories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tên thu chi
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên Thu Chi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),

            // Ngày, Tháng, Năm
            Row(
              children: <Widget>[
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ngày: ${_formatDate(_selectedDate)}', // Sử dụng hàm _formatDate
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Chọn Ngày'),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Số tiền
            TextField(
              controller: _amountController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Số Tiền (VNĐ)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 30),

            // Nút Thêm Giao Dịch
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Thêm Giao Dịch',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}