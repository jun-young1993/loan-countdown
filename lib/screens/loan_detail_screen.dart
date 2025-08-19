import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_common/flutter_common.dart';
import 'package:flutter_common/models/payment_schedule/index.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:loan_countdown/utills/format_currency.dart';
import 'package:flutter_common/state/payment_schedule/payment_schedule_page_bloc.dart';
import '../models/loan.dart';
import '../services/loan_calculator.dart';
import 'prepayment_screen.dart';
import 'graph_analysis_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MonthlyPayment>? _paymentSchedule;
  final bool _isLoadingSchedule = false;

  PaymentSchedulePageBloc? get _paymentScheduleBloc =>
      context.read<PaymentSchedulePageBloc>();

  late final _pagingController = PagingController<int, MonthlyPayment>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final result = LoanCalculator.generatePaymentSchedule(
        widget.loan,
        startMonth: pageKey == 1 ? 1 : (pageKey - 1) * 100 + 1,
        limit: pageKey == 1 ? 100 : (pageKey - 1) * 100 + 100,
      );

      return result;
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _paymentScheduleBloc?.add(ClearPaymentSchedule());
    _fetchPaymentSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPaymentSchedule() async {
    _paymentSchedule = LoanCalculator.generatePaymentSchedule(
      widget.loan,
      limit: widget.loan.term,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.loan.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrepaymentScreen(loan: widget.loan),
                ),
              );
            },
            icon: const Icon(Icons.payment),
            tooltip: '중도금 상환',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기본 정보'),
            Tab(text: '상환 스케줄'),
            Tab(text: '차트 분석'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBasicInfoTab(), _buildScheduleTab(), _buildChartTab()],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    final now = DateTime.now();
    final daysUntilStart = widget.loan.startDate.difference(now).inDays;
    final isStarted = daysUntilStart <= 0;
    final elapsedDays = isStarted ? widget.loan.getDaysSinceStart(now) : 0;
    final remainingDays = isStarted
        ? widget.loan.getRemainingDays(now)
        : widget.loan.term * 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // D-Day 상태 카드
          _buildDDayStatusCard(daysUntilStart, isStarted, elapsedDays),

          const SizedBox(height: 16),

          // 기본 정보 카드
          _buildBasicInfoCard(),

          const SizedBox(height: 16),

          // 상환 정보 카드
          _buildRepaymentInfoCard(remainingDays),

          const SizedBox(height: 16),

          // 추가 정보 카드
          _buildAdditionalInfoCard(),

          const SizedBox(height: 32),

          // 액션 버튼들
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDDayStatusCard(
    int daysUntilStart,
    bool isStarted,
    int elapsedDays,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String subtitle;

    if (isStarted) {
      statusColor = Colors.green;
      statusIcon = Icons.play_arrow;
      statusText = '진행 중';
      subtitle = 'D-Day +$elapsedDays일';
    } else if (daysUntilStart <= 7) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = '임박';
      subtitle = 'D-Day까지 $daysUntilStart일';
    } else if (daysUntilStart <= 30) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = '준비중';
      subtitle = 'D-Day까지 $daysUntilStart일';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
      statusText = '대기중';
      subtitle = 'D-Day까지 $daysUntilStart일';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isStarted ? '진행중' : 'D-$daysUntilStart',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  'D-Day',
                  _formatDate(widget.loan.startDate),
                  Icons.event,
                  statusColor,
                ),
                _buildStatusItem(
                  '대출 기간',
                  '${widget.loan.term}개월',
                  Icons.calendar_month,
                  statusColor,
                ),
                _buildStatusItem(
                  '상환 방식',
                  widget.loan.repaymentType.displayName,
                  Icons.payment,
                  statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
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
            fontSize: 14,
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

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '기본 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('대출명', widget.loan.name),
            _buildInfoRow('대출금액', formatCurrency(widget.loan.amount)),
            _buildInfoRow('이율', '${widget.loan.interestRate}%'),
            _buildInfoRow('대출 기간', '${widget.loan.term}개월'),
            if (widget.loan.initialPayment != null &&
                widget.loan.initialPayment! > 0)
              _buildInfoRow(
                '초기 납부금',
                formatCurrency(widget.loan.initialPayment!),
              ),
            if (widget.loan.paymentDay != null)
              _buildInfoRow('상환일', '매월 ${widget.loan.paymentDay}일'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentInfoCard(int remainingDays) {
    final totalAmount = widget.loan.amount;
    final monthlyPayment = _paymentSchedule?.isNotEmpty == true
        ? _paymentSchedule!.first.totalAmount
        : 0.0;
    final totalInterest = _paymentSchedule?.isNotEmpty == true
        ? _paymentSchedule!.fold(
            0.0,
            (sum, payment) => sum + payment.interestAmount,
          )
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '상환 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildRepaymentItem(
                    '월 납부금',
                    formatCurrency(monthlyPayment),
                    Icons.payment,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildRepaymentItem(
                    '총 이자',
                    formatCurrency(totalInterest),
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildRepaymentItem(
                    '총 상환금',
                    formatCurrency(totalAmount + totalInterest),
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildRepaymentItem(
                    '남은 기간',
                    '${(remainingDays / 30).round()}개월',
                    Icons.schedule,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepaymentItem(
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
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    final List<Widget> additionalItems = [];

    if (widget.loan.initialPayment != null && widget.loan.initialPayment! > 0) {
      additionalItems.add(
        _buildInfoRow('초기 납부금', formatCurrency(widget.loan.initialPayment!)),
      );
    }

    if (widget.loan.paymentDay != null) {
      additionalItems.add(
        _buildInfoRow('상환일', '매월 ${widget.loan.paymentDay}일'),
      );
    }

    if (additionalItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '추가 정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...additionalItems,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrepaymentScreen(loan: widget.loan),
                ),
              );
            },
            icon: const Icon(Icons.payment),
            label: const Text(
              '중도금 상환',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GraphAnalysisScreen(loan: widget.loan),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
            label: const Text(
              '고급 그래프 분석',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // 대출 수정 기능 (추후 구현)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('대출 수정 기능은 추후 업데이트 예정입니다.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('대출 정보 수정', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab() {
    return Column(
      children: [
        // 요약 정보 (로딩 중일 때는 기본값 표시)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '총 상환금',
                _paymentSchedule?.isNotEmpty == true
                    ? formatCurrency(
                        _paymentSchedule!.fold(
                          0.0,
                          (sum, payment) => sum + payment.totalAmount,
                        ),
                      )
                    : '계산 중...',
                Icons.payment,
                Colors.blue,
              ),
              _buildSummaryItem(
                '총 이자',
                _paymentSchedule?.isNotEmpty == true
                    ? formatCurrency(
                        LoanCalculator.calculateTotalInterest(
                          _paymentSchedule!,
                        ),
                      )
                    : '계산 중...',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildSummaryItem(
                '월 평균',
                _paymentSchedule?.isNotEmpty == true
                    ? formatCurrency(
                        _paymentSchedule!.fold(
                              0.0,
                              (sum, payment) => sum + payment.totalAmount,
                            ) /
                            _paymentSchedule!.length,
                      )
                    : '계산 중...',
                Icons.percent,
                Colors.green,
              ),
            ],
          ),
        ),

        // 상환 스케줄 테이블 (무한 스크롤)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child:
                BlocBuilder<
                  PaymentSchedulePageBloc,
                  PagingState<int, PaymentSchedule>
                >(
                  bloc: _paymentScheduleBloc,
                  builder: (context, state) =>
                      PagedListView<int, PaymentSchedule>(
                        state: state,
                        fetchNextPage: () {
                          _paymentScheduleBloc?.add(
                            FetchNextPaymentSchedule(widget.loan.id),
                          );
                        },
                        builderDelegate:
                            PagedChildBuilderDelegate<PaymentSchedule>(
                              itemBuilder: (context, payment, index) =>
                                  _buildPaymentRow(payment),
                              firstPageProgressIndicatorBuilder: (context) =>
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              newPageProgressIndicatorBuilder: (context) =>
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              noItemsFoundIndicatorBuilder: (context) =>
                                  const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          '상환 스케줄을 불러올 수 없습니다',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              noMoreItemsIndicatorBuilder: (context) =>
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        '모든 상환 스케줄을 불러왔습니다',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                      ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTab() {
    if (_isLoadingSchedule ||
        _paymentSchedule == null ||
        _paymentSchedule!.isEmpty) {
      return const Center(child: Text('차트 데이터를 불러올 수 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 원금 vs 이자 비율 차트
          _buildPieChart(),

          const SizedBox(height: 24),

          // 월별 납부금 추이 차트
          _buildLineChart(),

          const SizedBox(height: 24),

          // 잔액 변화 차트
          _buildBalanceChart(),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final totalPrincipal = _paymentSchedule!.fold(
      0.0,
      (sum, payment) => sum + payment.principalAmount,
    );
    final totalInterest = _paymentSchedule!.fold(
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
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalPrincipal,
                      title: '원금\n${formatCurrency(totalPrincipal)}',
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
                      title: '이자\n${formatCurrency(totalInterest)}',
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

  Widget _buildLineChart() {
    final monthlyPayments = _paymentSchedule!
        .map((payment) => payment.totalAmount)
        .toList();
    final months = _paymentSchedule!
        .map((payment) => payment.paymentNumber.toDouble())
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
              '월별 납부금 추이',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(formatCurrency(value));
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
                        return FlSpot(entry.value, monthlyPayments[entry.key]);
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

  Widget _buildBalanceChart() {
    final balances = _paymentSchedule!
        .map((payment) => payment.remainingBalance)
        .toList();
    final months = _paymentSchedule!
        .map((payment) => payment.paymentNumber.toDouble())
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
              '잔액 변화',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(formatCurrency(value));
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
                        return FlSpot(entry.value, balances[entry.key]);
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
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
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
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 개별 상환 행 위젯
  Widget _buildPaymentRow(PaymentSchedule payment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 월 정보와 납부일
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${payment.paymentNumber}개월',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDate(payment.paymentDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 상환 정보 그리드
            Row(
              children: [
                Expanded(
                  child: _buildPaymentInfoItem(
                    '원금',
                    formatCurrency(payment.principalAmount),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildPaymentInfoItem(
                    '이자',
                    formatCurrency(payment.interestAmount),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentInfoItem(
                    '총 납부금',
                    formatCurrency(payment.totalAmount),
                    Icons.payment,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildPaymentInfoItem(
                    '잔액',
                    formatCurrency(payment.remainingBalance),
                    Icons.account_balance,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 상환 정보 아이템 위젯
  Widget _buildPaymentInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
}
