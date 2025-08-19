import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/loan.dart';
import '../services/loan_calculator.dart';

class GraphAnalysisScreen extends StatefulWidget {
  final Loan loan;

  const GraphAnalysisScreen({super.key, required this.loan});

  @override
  State<GraphAnalysisScreen> createState() => _GraphAnalysisScreenState();
}

class _GraphAnalysisScreenState extends State<GraphAnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<MonthlyPayment>? _originalSchedule;
  List<MonthlyPayment>? _prepaymentSchedule;
  bool _isLoading = false;
  double _prepaymentAmount = 0.0;
  final DateTime _prepaymentDate = DateTime.now();
  PrepaymentType _prepaymentType = PrepaymentType.reduceAmount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOriginalSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOriginalSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _originalSchedule = LoanCalculator.generatePaymentSchedule(widget.loan);
    } catch (e) {
      print('상환 스케줄 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculatePrepaymentScenario() async {
    if (_prepaymentAmount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _prepaymentSchedule = LoanCalculator.recalculateAfterPrepayment(
        widget.loan,
        _originalSchedule!,
        _prepaymentAmount,
        _prepaymentDate,
        _prepaymentType,
      );
    } catch (e) {
      print('중도금 상환 계산 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.loan.name} - 그래프 분석',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '원금/이자'),
            Tab(text: '납부금 추이'),
            Tab(text: '잔액 변화'),
            Tab(text: '중도금 비교'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPrincipalInterestTab(),
                _buildPaymentTrendTab(),
                _buildBalanceChangeTab(),
                _buildPrepaymentComparisonTab(),
              ],
            ),
    );
  }

  Widget _buildPrincipalInterestTab() {
    if (_originalSchedule == null || _originalSchedule!.isEmpty) {
      return const Center(child: Text('데이터를 불러올 수 없습니다.'));
    }

    final monthlyData = _originalSchedule!;
    final principalData = monthlyData
        .map((payment) => payment.principalAmount)
        .toList();
    final interestData = monthlyData
        .map((payment) => payment.interestAmount)
        .toList();
    final months = monthlyData
        .map((payment) => payment.paymentNumber.toDouble())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 요약 정보
          _buildSummaryCard(),

          const SizedBox(height: 24),

          // 원금 vs 이자 스택 차트
          _buildStackedAreaChart(months, principalData, interestData),

          const SizedBox(height: 24),

          // 원금 vs 이자 비율 파이 차트
          _buildPieChart(),

          const SizedBox(height: 24),

          // 월별 원금/이자 바 차트
          _buildBarChart(months, principalData, interestData),
        ],
      ),
    );
  }

  Widget _buildPaymentTrendTab() {
    if (_originalSchedule == null || _originalSchedule!.isEmpty) {
      return const Center(child: Text('데이터를 불러올 수 없습니다.'));
    }

    final monthlyData = _originalSchedule!;
    final totalPayments = monthlyData
        .map((payment) => payment.totalAmount)
        .toList();
    final months = monthlyData
        .map((payment) => payment.paymentNumber.toDouble())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 납부금 통계
          _buildPaymentStatsCard(),

          const SizedBox(height: 24),

          // 월별 납부금 라인 차트
          _buildLineChart(months, totalPayments, '월별 납부금 추이'),

          const SizedBox(height: 24),

          // 납부금 분포 히스토그램
          _buildHistogram(totalPayments),
        ],
      ),
    );
  }

  Widget _buildBalanceChangeTab() {
    if (_originalSchedule == null || _originalSchedule!.isEmpty) {
      return const Center(child: Text('데이터를 불러올 수 없습니다.'));
    }

    final monthlyData = _originalSchedule!;
    final balances = monthlyData
        .map((payment) => payment.remainingBalance)
        .toList();
    final months = monthlyData
        .map((payment) => payment.paymentNumber.toDouble())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 잔액 통계
          _buildBalanceStatsCard(),

          const SizedBox(height: 24),

          // 잔액 변화 라인 차트
          _buildLineChart(months, balances, '잔액 변화'),

          const SizedBox(height: 24),

          // 상환 진행률 게이지
          _buildProgressGauge(),
        ],
      ),
    );
  }

  Widget _buildPrepaymentComparisonTab() {
    if (_originalSchedule == null || _originalSchedule!.isEmpty) {
      return const Center(child: Text('데이터를 불러올 수 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 중도금 상환 입력 폼
          _buildPrepaymentInputForm(),

          const SizedBox(height: 24),

          // 비교 차트
          if (_prepaymentSchedule != null) ...[
            _buildComparisonChart(),
            const SizedBox(height: 24),
            _buildSavingsAnalysisCard(),
          ] else ...[
            _buildNoPrepaymentCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalPrincipal = _originalSchedule!.fold(
      0.0,
      (sum, payment) => sum + payment.principalAmount,
    );
    final totalInterest = _originalSchedule!.fold(
      0.0,
      (sum, payment) => sum + payment.interestAmount,
    );
    final totalPayment = totalPrincipal + totalInterest;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '원금 vs 이자 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '총 원금',
                    '${(totalPrincipal / 10000).toStringAsFixed(1)}만원',
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '총 이자',
                    '${(totalInterest / 10000).toStringAsFixed(1)}만원',
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '총 상환금',
                    '${(totalPayment / 10000).toStringAsFixed(1)}만원',
                    Icons.payment,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStackedAreaChart(
    List<double> months,
    List<double> principalData,
    List<double> interestData,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '원금 vs 이자 스택 차트',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 10000).toStringAsFixed(0)}만원',
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}월');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: months.asMap().entries.map((entry) {
                        return FlSpot(entry.value, principalData[entry.key]);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    LineChartBarData(
                      spots: months.asMap().entries.map((entry) {
                        return FlSpot(entry.value, interestData[entry.key]);
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final totalPrincipal = _originalSchedule!.fold(
      0.0,
      (sum, payment) => sum + payment.principalAmount,
    );
    final totalInterest = _originalSchedule!.fold(
      0.0,
      (sum, payment) => sum + payment.interestAmount,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '원금 vs 이자 비율',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalPrincipal,
                      title:
                          '원금\n${(totalPrincipal / 10000).toStringAsFixed(1)}만원',
                      color: Colors.blue,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: totalInterest,
                      title:
                          '이자\n${(totalInterest / 10000).toStringAsFixed(1)}만원',
                      color: Colors.orange,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(
    List<double> months,
    List<double> principalData,
    List<double> interestData,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '월별 원금/이자 바 차트',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: principalData.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 10000).toStringAsFixed(0)}만원',
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}월');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: months.asMap().entries.map((entry) {
                    final month = entry.key;
                    return BarChartGroupData(
                      x: month,
                      barRods: [
                        BarChartRodData(
                          toY: principalData[month],
                          color: Colors.blue,
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: interestData[month],
                          color: Colors.orange,
                          width: 8,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatsCard() {
    final totalPayments = _originalSchedule!
        .map((payment) => payment.totalAmount)
        .toList();
    final avgPayment =
        totalPayments.reduce((a, b) => a + b) / totalPayments.length;
    final maxPayment = totalPayments.reduce((a, b) => a > b ? a : b);
    final minPayment = totalPayments.reduce((a, b) => a < b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '납부금 통계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '평균',
                    '${(avgPayment / 10000).toStringAsFixed(1)}만원',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '최대',
                    '${(maxPayment / 10000).toStringAsFixed(1)}만원',
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '최소',
                    '${(minPayment / 10000).toStringAsFixed(1)}만원',
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<double> months, List<double> data, String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 10000).toStringAsFixed(0)}만원',
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}월');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: months.asMap().entries.map((entry) {
                        return FlSpot(entry.value, data[entry.key]);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistogram(List<double> data) {
    // 간단한 히스토그램 구현
    final buckets = <String, int>{};
    final bucketSize = 1000000; // 100만원 단위

    for (final value in data) {
      final bucket = (value / bucketSize).floor() * bucketSize;
      final bucketKey = '${(bucket / 10000).toStringAsFixed(0)}만원';
      buckets[bucketKey] = (buckets[bucketKey] ?? 0) + 1;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '납부금 분포',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: buckets.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}건');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final keys = buckets.keys.toList();
                          if (value.toInt() < keys.length) {
                            return Text(keys[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: buckets.entries.map((entry) {
                    final index = buckets.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.purple,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceStatsCard() {
    final balances = _originalSchedule!
        .map((payment) => payment.remainingBalance)
        .toList();
    final initialBalance = balances.first;
    final finalBalance = balances.last;
    final avgBalance = balances.reduce((a, b) => a + b) / balances.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '잔액 통계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '초기 잔액',
                    '${(initialBalance / 10000).toStringAsFixed(1)}만원',
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '평균 잔액',
                    '${(avgBalance / 10000).toStringAsFixed(1)}만원',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '최종 잔액',
                    '${(finalBalance / 10000).toStringAsFixed(1)}만원',
                    Icons.account_balance_wallet,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressGauge() {
    final totalMonths = widget.loan.term;
    final currentMonth =
        DateTime.now().difference(widget.loan.startDate).inDays / 30;
    final progress = (currentMonth / totalMonths).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상환 진행률',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.5 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${currentMonth.round()}개월 / $totalMonths개월',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepaymentInputForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '중도금 상환 시나리오',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '상환 금액 (만원)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _prepaymentAmount = (double.tryParse(value) ?? 0.0) * 10000;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PrepaymentType>(
              value: _prepaymentType,
              decoration: const InputDecoration(
                labelText: '상환 방식',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: PrepaymentType.values.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.name));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _prepaymentType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _prepaymentAmount > 0
                    ? _calculatePrepaymentScenario
                    : null,
                child: const Text('시나리오 계산'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    if (_prepaymentSchedule == null) return const SizedBox.shrink();

    final originalPayments = _originalSchedule!
        .map((p) => p.totalAmount)
        .toList();
    final prepaymentPayments = _prepaymentSchedule!
        .map((p) => p.totalAmount)
        .toList();
    final months = _originalSchedule!
        .map((p) => p.paymentNumber.toDouble())
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '원본 vs 중도금 상환 비교',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 10000).toStringAsFixed(0)}만원',
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}월');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: months.asMap().entries.map((entry) {
                        return FlSpot(entry.value, originalPayments[entry.key]);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: months.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.value,
                          prepaymentPayments[entry.key],
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('원본 상환'),
                const SizedBox(width: 24),
                Container(width: 16, height: 16, color: Colors.green),
                const SizedBox(width: 8),
                const Text('중도금 상환 후'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsAnalysisCard() {
    if (_prepaymentSchedule == null) return const SizedBox.shrink();

    final originalTotal = _originalSchedule!.fold(
      0.0,
      (sum, p) => sum + p.totalAmount,
    );
    final prepaymentTotal = _prepaymentSchedule!.fold(
      0.0,
      (sum, p) => sum + p.totalAmount,
    );
    final savings = originalTotal - prepaymentTotal;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '절약 효과 분석',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '원본 총액',
                    '${(originalTotal / 10000).toStringAsFixed(1)}만원',
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '상환 후 총액',
                    '${(prepaymentTotal / 10000).toStringAsFixed(1)}만원',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '절약 금액',
                    '${(savings / 10000).toStringAsFixed(1)}만원',
                    Icons.savings,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPrepaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '중도금 상환 시나리오를 입력하세요',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '상환 금액과 방식을 선택하면\n절약 효과를 분석할 수 있습니다',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
