import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_common/constants/size_constants.dart';
import 'package:flutter_common/flutter_common.dart';
import 'package:flutter_common/models/payment_schedule/index.dart';
import 'package:flutter_common/state/payment_schedule/payment_schedule_bloc.dart';
import 'package:flutter_common/state/payment_schedule/payment_schedule_event.dart';
import 'package:google_mobile_ads/src/ad_containers.dart' hide AdError;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:loan_countdown/providers/loan_provider.dart';
import 'package:loan_countdown/utills/format_currency.dart';
import 'package:flutter_common/state/payment_schedule/payment_schedule_page_bloc.dart';
import '../models/loan.dart';
import '../services/loan_calculator.dart';
import 'prepayment_screen.dart';
import 'graph_analysis_screen.dart';

class LaonDetailInterstitialAdCallback extends AdCallback {
  @override
  void onAdClicked() {
    // TODO: implement onAdClicked
  }

  @override
  void onAdClosed() {
    // TODO: implement onAdClosed
  }

  @override
  void onAdFailedToLoad(AdError error) {
    // TODO: implement onAdFailedToLoad
  }

  @override
  void onAdLoaded() {
    // TODO: implement onAdLoaded
  }

  @override
  void onAdShown() {
    // TODO: implement onAdShown
  }

  @override
  void onInterstitialAdLoaded(InterstitialAd ad) {
    // TODO: implement onInterstitialAdLoaded
    ad.show();
  }

  @override
  void onRewardedAdLoaded(RewardedAd ad) {
    // TODO: implement onRewardedAdLoaded
  }

  @override
  void onRewardedAdUserEarnedReward(RewardItem reward) {
    // TODO: implement onRewardedAdUserEarnedReward
  }
}

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
  bool toggleOrder = false;
  String? selectedPaymentStatus;
  String? selectedMonth;

  PaymentSchedulePageBloc? get _paymentSchedulePageBloc =>
      context.read<PaymentSchedulePageBloc>();

  PaymentScheduleBloc? get _paymentScheduleBloc =>
      context.read<PaymentScheduleBloc>();

  LoanSummeryBloc? get _loanSummeryBloc => context.read<LoanSummeryBloc>();

  final AdMaster _adMaster = AdMaster();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _paymentSchedulePageBloc?.add(ClearPaymentSchedule());
    _paymentScheduleBloc?.add(GetPaymentStatus());
    _loanSummeryBloc?.add(GetLoanSummery(widget.loan.id));

    _adMaster.createInterstitialAd(
      adUnitId: Platform.isIOS
          ? 'ca-app-pub-4656262305566191/2167432446'
          : 'ca-app-pub-4656262305566191/7548569879',
      callback: LaonDetailInterstitialAdCallback(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleOrder() {
    setState(() {
      toggleOrder = !toggleOrder;
    });

    _paymentSchedulePageBloc?.add(ChangeOrder(toggleOrder ? 'DESC' : 'ASC'));
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('필터 설정'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상환 상태 필터
                  Row(
                    children: [
                      const Text('상환 상태: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedPaymentStatus,
                          hint: const Text('상환 상태 선택'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('전체'),
                            ),
                            const DropdownMenuItem(
                              value: 'PAID',
                              child: Text('상환 완료'),
                            ),
                            const DropdownMenuItem(
                              value: 'UNPAID',
                              child: Text('미상환'),
                            ),
                            const DropdownMenuItem(
                              value: 'OVERDUE',
                              child: Text('연체'),
                            ),
                          ],
                          onChanged: (String? value) {
                            setDialogState(() {
                              selectedPaymentStatus = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 월별 필터
                  Row(
                    children: [
                      const Text('월별 필터: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedMonth,
                          hint: const Text('월 선택'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('전체'),
                            ),
                            ...List.generate(12, (index) {
                              final month = index + 1;
                              return DropdownMenuItem(
                                value: month.toString(),
                                child: Text('$month월'),
                              );
                            }),
                          ],
                          onChanged: (String? value) {
                            setDialogState(() {
                              selectedMonth = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      // 필터 적용 로직
                      if (selectedPaymentStatus != null ||
                          selectedMonth != null) {
                        // 필터가 적용되었음을 표시하기 위해 상태 업데이트
                        // 실제 필터링은 Bloc에서 처리하거나 여기서 처리할 수 있습니다
                        print(
                          '필터 적용됨 - 상환 상태: $selectedPaymentStatus, 월: $selectedMonth',
                        );
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('적용'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedPaymentStatus = null;
                      selectedMonth = null;
                    });
                  },
                  child: const Text('초기화'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      selectedPaymentStatus = null;
      selectedMonth = null;
    });
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'PAID':
        return '상환 완료';
      case 'UNPAID':
        return '미상환';
      case 'OVERDUE':
        return '연체';
      default:
        return status;
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                '대출 삭제',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.loan.name} 대출을 삭제하시겠습니까?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '이 작업은 되돌릴 수 없으며, 모든 대출 정보와 상환 스케줄이 영구적으로 삭제됩니다.',
                        style: TextStyle(fontSize: 14, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: _deleteLoan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '삭제',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteLoan() async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('대출을 삭제하는 중...'),
              ],
            ),
          );
        },
      );

      // TODO: 실제 삭제 로직 구현
      // await _loanRepository.deleteLoan(widget.loan.id);
      await context.read<LoanProvider>().deleteLoan(widget.loan);
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // 확인 다이얼로그 닫기
      Navigator.of(context).pop();

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${widget.loan.name} 대출이 삭제되었습니다.'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );

      // 홈 화면으로 돌아가기
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('대출 삭제 중 오류가 발생했습니다: $e'),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
          // 중도금 상환 버튼
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
          // 삭제 버튼
          IconButton(
            onPressed: _showDeleteConfirmDialog,
            icon: const Icon(Icons.delete_outline),
            tooltip: '대출 삭제',
            style: IconButton.styleFrom(foregroundColor: Colors.red[600]),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: Tr.loan.basicInfo.tr()),
            Tab(text: Tr.loan.repaymentSchedule.tr()),
            // Tab(text: '차트 분석'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(), _buildScheduleTab(),
          // , _buildChartTab()
        ],
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
      statusText = Tr.loan.inProgress.tr();
      subtitle = 'D-Day +$elapsedDays ${Tr.loan.day.tr()}';
    } else if (daysUntilStart <= 7) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = Tr.loan.near.tr();
      subtitle = 'D-Day -$daysUntilStart ${Tr.loan.day.tr()}';
    } else if (daysUntilStart <= 30) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = Tr.loan.preparing.tr();
      subtitle = 'D-Day -$daysUntilStart ${Tr.loan.day.tr()}';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
      statusText = Tr.loan.waiting.tr();
      subtitle = 'D-Day -$daysUntilStart ${Tr.loan.day.tr()}';
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
                    isStarted ? Tr.loan.inProgress.tr() : 'D-$daysUntilStart',
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
    return Container(
      alignment: Alignment.centerLeft,
      width: 100,
      child: Column(
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
            textAlign: TextAlign.left,
            maxLines: 1, // 최대 3줄까지 표시
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.left,
            maxLines: 1, // 최대 3줄까지 표시
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
                Text(
                  Tr.loan.basicInfo.tr(),
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
        const SizedBox(height: 12),
        // 삭제 버튼
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showDeleteConfirmDialog,
            icon: Icon(Icons.delete_outline, color: Colors.red[600]),
            label: Text(
              '대출 삭제',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: BorderSide(color: Colors.red[300]!),
              backgroundColor: Colors.red[50],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab() {
    return Column(
      children: [
        // 요약 정보 카드 (접을 수 있음) - 간격 최소화
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ), // vertical margin 최소화
          child: ExpansionTile(
            initiallyExpanded: false, // 기본적으로 접혀있음
            title: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  Tr.loan.repaymentSummary.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            children: [_buildScheduleSummaryCardContent()],
          ),
        ),

        // 상환 스케줄 테이블 (무한 스크롤) - 더 많은 공간 확보
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child:
                      BlocBuilder<
                        PaymentSchedulePageBloc,
                        PagingState<int, PaymentSchedule>
                      >(
                        bloc: _paymentSchedulePageBloc,
                        builder: (context, state) =>
                            PagedListView<int, PaymentSchedule>(
                              state: state,
                              fetchNextPage: () {
                                _paymentSchedulePageBloc?.add(
                                  FetchNextPaymentSchedule(widget.loan.id),
                                );
                              },
                              builderDelegate:
                                  PagedChildBuilderDelegate<PaymentSchedule>(
                                    itemBuilder: (context, payment, index) =>
                                        _buildScheduleTableRow(payment),
                                    firstPageProgressIndicatorBuilder:
                                        (context) => const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                    newPageProgressIndicatorBuilder:
                                        (context) => const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                    noItemsFoundIndicatorBuilder: (context) =>
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.schedule,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                Tr
                                                    .loan
                                                    .repaymentSummaryLoadError
                                                    .tr(),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    noMoreItemsIndicatorBuilder: (context) =>
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(
                                              Tr
                                                  .loan
                                                  .repaymentSummaryLoadSuccess
                                                  .tr(),
                                              style: const TextStyle(
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

                // 정렬 버튼을 상환 스케줄 테이블 콘테이너 기준 오른쪽 상단에 배치
                Positioned(
                  top: 0, // 헤더와 요약 카드 높이를 고려한 위치
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPositionedButton(
                        icon: Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: SizeConstants.getSmallIconSize(context),
                        ),
                        onTap: _showFilterDialog,
                      ),
                      const SizedBox(width: 24),
                      _buildPositionedButton(
                        icon: Icon(
                          toggleOrder
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: Colors.white,
                          size: SizeConstants.getSmallIconSize(context),
                        ),
                        onTap: _toggleOrder,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionedButton({
    required Icon icon,
    required Function() onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: SizeConstants.getSmallButtonPadding(context),
            child: icon,
          ),
        ),
      ),
    );
  }

  // 상환 스케줄 헤더 (검색, 필터)
  Widget _buildScheduleHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.table_chart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '상환 스케줄',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // 필터 초기화 버튼 (필터가 적용되었을 때만 표시)
                  if (selectedPaymentStatus != null || selectedMonth != null)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('필터 초기화'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                ],
              ),
              // 필터 상태 표시
              if (selectedPaymentStatus != null || selectedMonth != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (selectedPaymentStatus != null)
                      Chip(
                        label: Text(
                          _getPaymentStatusText(selectedPaymentStatus!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedPaymentStatus = null;
                          });
                        },
                      ),
                    if (selectedMonth != null)
                      Chip(
                        label: Text(
                          '$selectedMonth월',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedMonth = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 상환 스케줄 요약 정보 카드 내용
  // 상환 스케줄 요약 정보 카드 내용
  Widget _buildScheduleSummaryCardContent() {
    return LoanSummeryRepaymentSummarySelector((summary) {
      if (summary == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // 첫 번째 줄 (4개 항목)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.totalRepaymentAmount.tr(),
                    formatCurrency(summary.totalRepaymentAmount),
                    Icons.payment,
                    Colors.blue,
                    Tr.loan.totalRepaymentAmountDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.totalInterestAmount.tr(),
                    formatCurrency(summary.totalInterestAmount),
                    Icons.trending_up,
                    Colors.orange,
                    Tr.loan.totalInterestAmountDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.averageMonthlyPayment.tr(),
                    formatCurrency(summary.averageMonthlyPayment),
                    Icons.percent,
                    Colors.green,
                    Tr.loan.averageMonthlyPaymentDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.remainingPrincipal.tr(),
                    formatCurrency(summary.remainingPrincipal),
                    Icons.account_balance,
                    Colors.red,
                    Tr.loan.remainingPrincipalDescription.tr(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 두 번째 줄 (4개 항목)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.remainingInterest.tr(),
                    formatCurrency(summary.remainingInterest),
                    Icons.trending_up,
                    Colors.deepOrange,
                    Tr.loan.remainingInterestDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.repaymentProgress.tr(),
                    '${summary.repaymentProgress.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    Colors.teal,
                    Tr.loan.repaymentProgressDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.interestRatio.tr(),
                    '${summary.interestRatio.toStringAsFixed(1)}%',
                    Icons.analytics,
                    Colors.indigo,
                    Tr.loan.interestRatioDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.principalRatio.tr(),
                    '${summary.principalRatio.toStringAsFixed(1)}%',
                    Icons.account_balance_wallet,
                    Colors.cyan,
                    Tr.loan.principalRatioDescription.tr(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 세 번째 줄 (4개 항목)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.completedPayments.tr(),
                    '${summary.completedPayments}건',
                    Icons.check_circle,
                    Colors.lightGreen,
                    Tr.loan.completedPaymentsDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.totalPayments.tr(),
                    '${summary.totalPayments}건',
                    Icons.list_alt,
                    Colors.grey,
                    Tr.loan.totalPaymentsDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.overduePayments.tr(),
                    '${summary.overduePayments}건',
                    Icons.warning,
                    Colors.amber,
                    Tr.loan.overduePaymentsDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.nextPaymentDate.tr(),
                    _formatDate(summary.nextPaymentDate),
                    Icons.event,
                    Colors.pink,
                    Tr.loan.nextPaymentDateDescription.tr(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 네 번째 줄 (2개 항목 - 중도상환 관련)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.totalPrepaymentAmount.tr(),
                    formatCurrency(summary.totalPrepaymentAmount),
                    Icons.money_off,
                    Colors.deepPurple,
                    Tr.loan.totalPrepaymentAmountDescription.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryGridItem(
                    Tr.loan.prepaymentInterestSavings.tr(),
                    formatCurrency(summary.prepaymentInterestSavings),
                    Icons.savings,
                    Colors.lightBlue,
                    Tr.loan.prepaymentInterestSavingsDescription.tr(),
                  ),
                ),
                const Spacer(flex: 2), // 나머지 공간을 차지
              ],
            ),
          ],
        ),
      );
    });
  }

  // 요약 그리드 아이템
  Widget _buildSummaryGridItem(
    String title,
    String value,
    IconData icon,
    Color color,
    String? description,
  ) {
    return GestureDetector(
      onTap: () {
        if (description != null && description.isNotEmpty) {
          _showDescriptionAlert(title, description, value);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            // 설명이 있을 때 터치 가능함을 표시하는 인디케이터
            if (description != null && description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: color.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 설명 알럿 표시 함수
  void _showDescriptionAlert(String title, String description, String value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 값 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Tr.loan.currentValue.tr(namedArgs: {'value': value}),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 설명 텍스트
              Text(
                Tr.loan.description.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                Tr.loan.confirm.tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // 상환 스케줄 테이블 행 (가로형 레이아웃으로 최적화)
  Widget _buildScheduleTableRow(PaymentSchedule payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 첫 번째 행: 월 정보와 상태 (가로 배치)
              Row(
                children: [
                  // 월 정보 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Tr.loan.months.tr(
                        namedArgs: {'month': payment.paymentNumber.toString()},
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 납부일
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(payment.paymentDate),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 상태 표시
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(payment.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 두 번째 행: 금액 정보를 가로형 테이블로 배치
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 원금
                      Expanded(
                        child: _buildHorizontalAmountItem(
                          Tr.loan.principal.tr(),
                          formatCurrency(payment.principalAmount),
                          Colors.blue,
                        ),
                      ),

                      // 이자
                      Expanded(
                        child: _buildHorizontalAmountItem(
                          Tr.loan.interest.tr(),
                          formatCurrency(payment.interestAmount),
                          Colors.orange,
                        ),
                      ),

                      // 총액
                      Expanded(
                        child: _buildHorizontalAmountItem(
                          Tr.loan.totalAmount.tr(),
                          formatCurrency(payment.totalAmount),
                          Colors.green,
                        ),
                      ),

                      // 잔액
                      Expanded(
                        child: _buildHorizontalAmountItem(
                          Tr.loan.remainingBalance.tr(),
                          formatCurrency(payment.remainingBalance),
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 세 번째 행: 추가 정보 (있는 경우에만)
              if (payment.notes != null && payment.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            payment.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 가로형 금액 정보 아이템 위젯
  Widget _buildHorizontalAmountItem(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab() {
    if (_isLoadingSchedule ||
        _paymentSchedule == null ||
        _paymentSchedule!.isEmpty) {
      return Center(child: Text(Tr.loan.chartDataLoadError.tr()));
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
            Text(
              Tr.loan.principalVsInterestRatio.tr(),
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
                      title:
                          Tr.loan.principal.tr() +
                          '\n${formatCurrency(totalPrincipal)}',
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
                          Tr.loan.interest.tr() +
                          '\n${formatCurrency(totalInterest)}',
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
            Text(
              Tr.loan.monthlyPaymentTrend.tr(),
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
                          return Text(
                            Tr.loan.month.tr(
                              namedArgs: {'month': value.toInt().toString()},
                            ),
                          );
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
            Text(
              Tr.loan.remainingAmountTrend.tr(),
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
                          return Text(
                            Tr.loan.month.tr(
                              namedArgs: {'month': value.toInt().toString()},
                            ),
                          );
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

  String _formatDate(DateTime date, {bool? ignoreYear = false}) {
    return '${ignoreYear == true ? '' : '${date.year}/'}${date.month}/${date.day}';
  }

  // 상태별 색상 반환
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case '납입완료':
        return Colors.green;
      case 'unpaid':
      case '미납':
        return Colors.orange;
      case 'overdue':
      case '연체':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 상태별 텍스트 반환
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case '납입완료':
        return Tr.loan.completed.tr();
      case 'unpaid':
      case '미납':
        return Tr.loan.uncomplete.tr();
      case 'overdue':
      case '연체':
        return Tr.loan.overdue.tr();
      default:
        return Tr.loan.waiting.tr();
    }
  }
}
