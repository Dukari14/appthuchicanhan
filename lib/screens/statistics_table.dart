import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thuchicanhan/core/data_manager.dart';

// Cấu trúc dữ liệu

class CategoryData {
  final String category;
  final double percentage;
  final String amount;
  CategoryData(this.category, this.percentage, this.amount);
}

class ChartData {
  final double income;
  final double expense;
  ChartData(this.income, this.expense);
}

// Widget Biểu đồ Đường (IncomeExpenseChart)

class IncomeExpenseChart extends StatelessWidget {
  final List<ChartData> dataToDisplay;

  const IncomeExpenseChart({super.key, required this.dataToDisplay});

  @override
  Widget build(BuildContext context) {
    int displayLength = dataToDisplay.length;

    if (displayLength == 0) {
      return const Center(child: Text("Không có dữ liệu biểu đồ cho năm/tháng đã chọn."));
    }

    // Tính toán max Y để biểu đồ tự co giãn
    double maxYValue = 0;
    for (var data in dataToDisplay) {
      if (data.income > maxYValue) maxYValue = data.income;
      if (data.expense > maxYValue) maxYValue = data.expense;
    }

    // Chuyển sang đơn vị triệu (M) và thêm đệm (làm tròn lên bội số của 5)
    double chartMaxY = ((maxYValue * 1.2) / 5).ceil() * 5;
    if (chartMaxY == 0) chartMaxY = 5;

    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 20),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  String text = 'Thg ${value.toInt() + 1}';
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4.0,
                    child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: chartMaxY > 10 ? 5 : 1,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                  return Text('${value.toInt()}M', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY > 10 ? 5 : 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1)),

          minX: 0,
          maxX: displayLength.toDouble() - 1,
          minY: 0,
          maxY: chartMaxY,

          lineBarsData: [
            // Đường Thu Nhập (Màu Xanh Dương)
            LineChartBarData(
              spots: List.generate(displayLength, (index) {
                return FlSpot(index.toDouble(), dataToDisplay[index].income);
              }),
              isCurved: true, color: Colors.blue, barWidth: 3, isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
            ),
            // Đường Chi Tiêu (Màu Đỏ)
            LineChartBarData(
              spots: List.generate(displayLength, (index) {
                return FlSpot(index.toDouble(), dataToDisplay[index].expense);
              }),
              isCurved: true, color: Colors.red, barWidth: 3, isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }
}

// ReportScreen State (Logic tính toán dữ liệu động)

class ReportScreen extends StatefulWidget {
  final List<Transaction> transactions;
  const ReportScreen({super.key, required this.transactions});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedYear = DateTime.now().year.toString();
  List<CategoryData> _currentCategoryData = [];
  List<ChartData> _currentChartData = [];

  late List<Transaction> _transactionsInYear;

  late List<String> _availableYears;

  @override
  void initState() {
    super.initState();
    _transactionsInYear = []; // Khởi tạo
    _initializeYears();
    _loadReportData();
  }

  void _initializeYears() {
    _availableYears = List.generate(
        3, (index) => (DateTime.now().year - index).toString());

    // Cập nhật danh sách năm khả dụng dựa trên dữ liệu thật
    if (widget.transactions.isNotEmpty) {
      final allYears = widget.transactions.map((t) => t.date.year.toString()).toSet().toList();
      allYears.sort((a, b) => b.compareTo(a)); // Sắp xếp giảm dần
      _availableYears = allYears.take(5).toList(); // Lấy tối đa 5 năm gần nhất có dữ liệu

      // Đặt năm mặc định là năm gần nhất có dữ liệu
      if (!_availableYears.contains(_selectedYear) && _availableYears.isNotEmpty) {
        _selectedYear = _availableYears.first;
      }
    } else {
      _selectedYear = DateTime.now().year.toString();
    }

  }


  @override
  void didUpdateWidget(covariant ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _initializeYears();
      _loadReportData();
    }
  }


  // HÀM TÍNH TOÁN DỮ LIỆU BÁO CÁO TỪ DANH SÁCH GIAO DỊCH
  void _loadReportData() {
    // Lọc giao dịch theo năm đã chọn
    _transactionsInYear = widget.transactions
        .where((t) => t.date.year.toString() == _selectedYear)
        .toList();

    // Tính toán Dữ liệu Biểu đồ (Thu/Chi theo tháng)
    final monthlySummary = List.generate(12, (_) => {'income': 0.0, 'expense': 0.0});

    for (var t in _transactionsInYear) { // SỬ DỤNG _transactionsInYear
      final monthIndex = t.date.month - 1;
      if (t.type == TransactionType.income) {
        monthlySummary[monthIndex]['income'] = monthlySummary[monthIndex]['income']! + t.amount;
      } else {
        monthlySummary[monthIndex]['expense'] = monthlySummary[monthIndex]['expense']! + t.amount;
      }
    }

    // Chuyển sang List<ChartData> (đơn vị Triệu - M)
    final chartData = monthlySummary.map((data) {
      return ChartData(data['income']! / 1000000, data['expense']! / 1000000);
    }).toList();

    // Giữ lại các tháng có dữ liệu (đến tháng hiện tại nếu là năm hiện tại, hoặc cả 12 tháng)
    final int currentMonth = DateTime.now().year.toString() == _selectedYear ? DateTime.now().month : 12;
    _currentChartData = chartData.sublist(0, currentMonth);


    // Tính toán Dữ liệu Danh mục Chi tiêu Hàng đầu
    double totalExpense = 0;
    final categoryExpenses = <String, double>{};

    // SỬ DỤNG _transactionsInYear
    for (var t in _transactionsInYear.where((t) => t.type == TransactionType.expense)) {
      totalExpense += t.amount;
      categoryExpenses[t.category] = (categoryExpenses[t.category] ?? 0) + t.amount;
    }

    _currentCategoryData = [];
    if (totalExpense > 0) {
      final sortedCategories = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _currentCategoryData = sortedCategories.map((entry) {
        final percentage = entry.value / totalExpense;
        return CategoryData(
          entry.key,
          percentage,
          formatNumber(entry.value) + ' VNĐ',
        );
      }).toList();
    }


    setState(() {
      // Dữ liệu đã được tính toán và cập nhật vào State
    });
  }

  // Widget hiển thị thanh tiến trình cho danh mục
  Widget _buildCategoryProgress(CategoryData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.category, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(data.amount, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: data.percentage,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // KIỂM TRA ĐIỀU KIỆN TỪ BIẾN STATE ĐÃ CẬP NHẬT
    final bool hasExpenseDataInYear = _transactionsInYear.any((t) => t.type == TransactionType.expense);
    final bool hasData = _transactionsInYear.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Tài Chính'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Khu vực Chọn Năm
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedYear,
                  dropdownColor: Colors.blue,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: _availableYears.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedYear = newValue;
                        _loadReportData();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề báo cáo
            Text('Xu Hướng Thu Chi (Năm $_selectedYear)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            // Biểu đồ (Truyền dữ liệu động)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    )
                  ]
              ),
              child: IncomeExpenseChart(dataToDisplay: _currentChartData),
            ),
            const SizedBox(height: 20),

            // Danh mục Chi tiêu Hàng đầu
            const Text('Danh Mục Chi Tiêu Hàng Đầu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // HIỂN THỊ DỮ LIỆU DANH MỤC HOẶC THÔNG BÁO KHÔNG CÓ DỮ LIỆU
            if (!hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text('Chưa có giao dịch nào trong năm đã chọn.')),
              )
            else if (!hasExpenseDataInYear)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text('Chưa có giao dịch chi tiêu nào trong năm đã chọn.')),
              )
            else
            // Lặp qua danh sách dữ liệu danh mục hiện tại
              ..._currentCategoryData.map((data) => _buildCategoryProgress(data)).toList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}