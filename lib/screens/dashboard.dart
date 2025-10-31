import 'package:flutter/material.dart';
// Thay thế import cũ
import 'package:thuchicanhan/core/data_manager.dart';

class DashboardPage extends StatelessWidget {
  // Nhận dữ liệu giao dịch từ MainScreen
  final List<Transaction> transactions;
  const DashboardPage({super.key, required this.transactions});

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionItem item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.color.withOpacity(0.15),
        child: Icon(item.icon, color: item.color, size: 20),
      ),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: const Text('Gần đây'),
      trailing: Text(
        item.amount,
        style: TextStyle(color: item.color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TÍNH TOÁN DỮ LIỆU TỔNG HỢP VÀ GIAO DỊCH GẦN ĐÂY
    final summary = calculateSummary(transactions);
    final recentTransactions = getRecentTransactions(transactions);

    final tongthunhap = summary['tongthunhap'] ?? 0;
    final thunhap = summary['thunhap'] ?? 0;
    final chitieu = summary['chitieu'] ?? 0;

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          flexibleSpace: const FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: 16.0),
            title: Text(
              'Tổng Số Dư Tháng Này',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          expandedHeight: 90.0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            title: Text(
              '${formatNumber(tongthunhap)} VNĐ',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildSummaryCard(
                            'Thu Nhập Tháng', '+ ${formatNumber(thunhap)} VNĐ', Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildSummaryCard(
                            'Chi Tiêu Tháng', '- ${formatNumber(chitieu)} VNĐ', Colors.red)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Text(
                  'Giao Dịch Gần Đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // SỬ DỤNG DỮ LIỆU TÍNH TOÁN ĐƯỢC
        SliverList.builder(
          itemCount: recentTransactions.length,
          itemBuilder: (context, index) {
            final transaction = recentTransactions[index];
            // Chỉ cần gọi _buildTransactionItem, không cần ListTile bao ngoài nữa
            return _buildTransactionItem(transaction);
          },
        ),
      ],
    );
  }
}