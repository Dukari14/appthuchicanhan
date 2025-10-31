import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:thuchicanhan/core/data_manager.dart';

class TransactionListPage extends StatefulWidget {
  // Nhận danh sách giao dịch hiện tại từ MainScreen
  final List<Transaction> transactions;
  // Callback để thông báo cho MainScreen cập nhật lại danh sách gốc
  final Function(List<Transaction>) onUpdateTransactions;

  const TransactionListPage({
    super.key,
    required this.transactions,
    required this.onUpdateTransactions,
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  // Bản sao cục bộ (dùng tạm thời)
  late List<Transaction> _currentTransactions;

  @override
  void initState() {
    super.initState();
    // Khởi tạo bản sao từ dữ liệu truyền vào
    _currentTransactions = List.from(widget.transactions);
  }

  // Cập nhật lại khi widget.transactions thay đổi (ví dụ: khi thêm giao dịch mới)
  @override
  void didUpdateWidget(covariant TransactionListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu dữ liệu gốc thay đổi (do thêm/sửa/xóa từ MainScreen hoặc màn hình khác), cập nhật bản sao cục bộ
    if (widget.transactions != oldWidget.transactions) {
      _currentTransactions = List.from(widget.transactions);
    }
  }


  // Các phương thức quản lý dữ liệu

  void _deleteTransaction(Transaction transactionToDelete) async {
    // Xóa khỏi bản sao cục bộ
    _currentTransactions.remove(transactionToDelete);
    // Gửi danh sách đã cập nhật lên MainScreen
    widget.onUpdateTransactions(_currentTransactions);
    SampleData.allTransactions.remove(transactionToDelete);

    try {
      await saveTransactionsToJsonFile(
        SampleData.allTransactions,
        'data.json',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa giao dịch thành công')),
      );
    } catch (e) {
      print('Lỗi khi lưu dữ liệu JSON: $e');
      // KIỂM TRA mounted TRƯỚC KHI TƯƠNG TÁC VỚI CONTEXT/UI
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không thể lưu dữ liệu!')),
      );
    }
  }

  void _editTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    // Tìm và cập nhật object trong bản sao cục bộ
    final index = _currentTransactions.indexOf(oldTransaction);
    if (index != -1) {
      _currentTransactions[index] = newTransaction;
    }
    // Gửi danh sách đã cập nhật lên MainScreen
    widget.onUpdateTransactions(_currentTransactions);
    SampleData.allTransactions[index] = newTransaction;

    try {
      await saveTransactionsToJsonFile(
        SampleData.allTransactions,
        'data.json',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật giao dịch: ${newTransaction.name}')),
      );
    } catch (e) {
      print('Lỗi khi lưu dữ liệu JSON: $e');
      // KIỂM TRA mounted TRƯỚC KHI TƯƠNG TÁC VỚI CONTEXT/UI
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không thể lưu dữ liệu!')),
      );
    }
  }

  // Widget giao diện

  @override
  Widget build(BuildContext context) {
    // Lọc dữ liệu từ _currentTransactions cho từng tab
    final incomeTransactions =
    _currentTransactions.where((t) => t.type == TransactionType.income).toList();
    final expenseTransactions =
    _currentTransactions.where((t) => t.type == TransactionType.expense).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Danh sách Thu Chi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '💰 Thu nhập'),
              Tab(text: '💸 Chi tiêu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Thu nhập
            TransactionListView(
              transactions: incomeTransactions,
              onDelete: _deleteTransaction,
              onEdit: _editTransaction,
            ),
            // Tab Chi tiêu
            TransactionListView(
              transactions: expenseTransactions,
              onDelete: _deleteTransaction,
              onEdit: _editTransaction,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget hiển thị danh sách giao dịch

class TransactionListView extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onDelete;
  final Function(Transaction, Transaction) onEdit;

  const TransactionListView({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
          child: Text('Không có giao dịch nào trong danh mục này.'));
    }

    // Sắp xếp theo ngày mới nhất lên trước
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionListItem(
          key: ObjectKey(transaction),
          transaction: transaction,
          onDelete: onDelete,
          onEdit: onEdit,
        );
      },
    );
  }
}

// Widget hiển thị từng mục giao dịch

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Function(Transaction) onDelete;
  final Function(Transaction, Transaction) onEdit;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  // Hiển thị dialog chỉnh sửa
  void _showEditDialog(BuildContext context) {
    // Tạo bản sao để tránh thay đổi trực tiếp
    Transaction tempTransaction = transaction.copyWith();

    final nameController = TextEditingController(text: tempTransaction.name);
    final amountController =
    TextEditingController(text: tempTransaction.amount.toString());

    // Danh mục dựa trên loại giao dịch
    final List<String> categories = tempTransaction.type == TransactionType.income
        ? ['Lương', 'Nguồn thu nhập khác']
        : ['Nhà cửa', 'Ăn uống', 'Giải trí', 'Đi lại', 'Khác'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Chỉnh sửa ${tempTransaction.type == TransactionType.income ? 'Thu nhập' : 'Chi tiêu'}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên thu chi'),
                    ),
                    const SizedBox(height: 10),
                    // Dropdown cho Danh mục
                    DropdownButtonFormField<String>(
                      value: tempTransaction.category,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            tempTransaction.category = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số tiền'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ngày: ${DateFormat('dd/MM/yyyy').format(tempTransaction.date)}'),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: tempTransaction.date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != tempTransaction.date) {
                              setState(() {
                                tempTransaction.date = picked;
                              });
                            }
                          },
                          child: const Text('Chọn ngày'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Xử lý và kiểm tra dữ liệu
                    final newAmount = double.tryParse(amountController.text.replaceAll(',', ''));
                    if (nameController.text.isEmpty || newAmount == null || newAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập đầy đủ và đúng định dạng.')),
                      );
                      return;
                    }

                    // Cập nhật các trường còn lại trong tempTransaction
                    tempTransaction.name = nameController.text;
                    tempTransaction.amount = newAmount;

                    // Gửi object đã chỉnh sửa và object gốc
                    onEdit(transaction, tempTransaction);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Định dạng số tiền
    final amountFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: ' VNĐ',
      decimalDigits: 0,
    );
    final formattedAmount = amountFormatter.format(transaction.amount);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final formattedDate = dateFormatter.format(transaction.date);

    final bool isIncome = transaction.type == TransactionType.income;
    final Color amountColor =
    isIncome ? Colors.green.shade700 : Colors.red.shade700;
    final IconData iconData = isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    final Color iconColor = isIncome ? Colors.green.shade100 : Colors.red.shade100;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor,
          child: Icon(iconData, color: amountColor, size: 20),
        ),
        title: Text(
          transaction.name, // Tên thu chi
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Danh mục: ${transaction.category}'), // Danh mục
            Text('Ngày: $formattedDate'), // Tháng, ngày, năm
            // HIỆN RÕ SỐ TIỀN VÀ LOẠI GIAO DỊCH
            Text(
              'Số tiền: ${isIncome ? '+' : '-'}$formattedAmount',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text('Loại giao dịch: ${isIncome ? 'Thu nhập' : 'Chi tiêu'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String result) {
            if (result == 'edit') {
              _showEditDialog(context);
            } else if (result == 'delete') {
              // Gọi hàm xóa và truyền object giao dịch cần xóa
              onDelete(transaction);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert), // Nút ba chấm dọc
        ),
      ),
    );
  }
}