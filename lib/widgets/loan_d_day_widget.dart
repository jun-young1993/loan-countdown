import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loan_countdown/models/loan.dart';
import 'package:loan_countdown/utills/format_currency.dart';

class LoanDDayWidget extends StatefulWidget {
  final List<Loan> loans; // List<Loan> 추가 (선택적)
  final int initialIndex; // 초기 인덱스 추가

  const LoanDDayWidget({
    super.key,
    required this.loans, // loans 파라미터 추가
    this.initialIndex = 0,
  });

  @override
  State<LoanDDayWidget> createState() => _LoanDDayWidgetState();
}

class _LoanDDayWidgetState extends State<LoanDDayWidget>
    with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _runningController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _runningAnimation;
  int _currentIndex = 0; // 현재 표시 중인 대출 인덱스

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // 펄스 애니메이션 초기화
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 페이드 애니메이션 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // 달리는 애니메이션 초기화
    _runningController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _runningAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _runningController, curve: Curves.linear),
    );

    // 애니메이션 시작
    _fadeController.forward();
    _startPulseAnimation();
    _startRunningAnimation();

    // 1초마다 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _runningController.dispose();
    super.dispose();
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _startRunningAnimation() {
    _runningController.repeat();
  }

  // 다음 대출로 이동
  void _nextLoan() {
    if (widget.loans.isNotEmpty) {
      // 페이드 아웃 후 상태 변경, 그 다음 페이드 인
      _fadeController.reverse().then((_) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.loans.length;
        });
        _fadeController.forward();
      });
    }
  }

  // 이전 대출로 이동
  void _previousLoan() {
    if (widget.loans.isNotEmpty) {
      // 페이드 아웃 후 상태 변경, 그 다음 페이드 인
      _fadeController.reverse().then((_) {
        setState(() {
          _currentIndex =
              (_currentIndex - 1 + widget.loans.length) % widget.loans.length;
        });
        _fadeController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loans.isEmpty) {
      return FadeTransition(opacity: _fadeAnimation, child: _buildNoLoanCard());
    }

    // 현재 선택된 대출
    final currentLoan = widget.loans[_currentIndex];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildCountdownCard(currentLoan, widget.loans),
    );
  }

  Widget _buildNoLoanCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[100]!, Colors.grey[200]!],
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              '등록된 대출이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 대출을 추가해보세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownCard(Loan loan, List<Loan> loans) {
    final now = DateTime.now();
    final daysUntilStart = loan.startDate.difference(now).inDays;
    final isStarted = daysUntilStart <= 0;
    final elapsedDays = isStarted ? loan.getDaysSinceStart(now) : 0;

    Color cardColor;
    IconData statusIcon;
    String statusText;

    if (daysUntilStart > 30) {
      cardColor = Colors.green;
      statusIcon = Icons.schedule;
      statusText = '대기중';
    } else if (daysUntilStart > 7) {
      cardColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = '준비중';
    } else if (daysUntilStart > 0) {
      cardColor = Colors.red;
      statusIcon = Icons.error;
      statusText = '임박';
    } else {
      cardColor = Colors.blue;
      statusIcon = Icons.play_arrow;
      statusText = '진행중';
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor.withOpacity(0.1), cardColor.withOpacity(0.05)],
          ),
        ),
        child: Column(
          children: [
            // 네비게이션 컨트롤 추가 (대출이 2개 이상일 때만)
            if (loans.length > 1) ...[
              _buildNavigationControls(loans),
              const SizedBox(height: 16),
            ],

            // 대출명과 상태
            Row(
              children: [
                Icon(statusIcon, color: cardColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // D-Day 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  'D-Day',
                  _formatDate(loan.startDate),
                  Icons.event,
                  cardColor,
                ),
                _buildInfoColumn(
                  '대출금액',
                  formatCurrency(loan.amount),
                  Icons.attach_money,
                  cardColor,
                ),
                _buildInfoColumn(
                  '이율',
                  '${loan.interestRate}%',
                  Icons.percent,
                  cardColor,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 카운트다운 또는 경과일
            if (isStarted) ...[
              _buildElapsedDaysCard(elapsedDays, cardColor),
            ] else ...[
              _buildCountdownDisplay(daysUntilStart, cardColor),
            ],

            const SizedBox(height: 16),

            // 프로그레스 바와 달리는 애니메이션
            _buildProgressSection(loan, cardColor),

            const SizedBox(height: 16),

            // 추가 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  '상환 방식',
                  loan.repaymentType.displayName,
                  Icons.payment,
                ),
                _buildDetailItem(
                  '대출 기간',
                  '${loan.term}개월',
                  Icons.calendar_month,
                ),
                if (loan.paymentDay != null)
                  _buildDetailItem(
                    '상환일',
                    '매월 ${loan.paymentDay}일',
                    Icons.schedule,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 네비게이션 컨트롤 위젯
  Widget _buildNavigationControls(List<Loan> loans) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 이전 버튼
        IconButton(
          onPressed: _fadeController.isAnimating ? null : _previousLoan,
          icon: const Icon(Icons.chevron_left),
          tooltip: '이전 대출',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: _fadeController.isAnimating
                ? Colors.grey[400]
                : Colors.grey[700],
          ),
        ),

        // 현재 위치 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1} / ${loans.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ),

        // 다음 버튼
        IconButton(
          onPressed: _fadeController.isAnimating ? null : _nextLoan,
          icon: const Icon(Icons.chevron_right),
          tooltip: '다음 대출',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: _fadeController.isAnimating
                ? Colors.grey[400]
                : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(
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

  Widget _buildCountdownDisplay(int days, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'D-Day까지',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Text(
              '$days일',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElapsedDaysCard(int days, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'D-Day +',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$days일',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text('진행 중', style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 경과 개월 수 계산
  int _calculateElapsedMonths(DateTime startDate, DateTime currentDate) {
    if (currentDate.isBefore(startDate)) return 0;

    final yearDiff = currentDate.year - startDate.year;
    final monthDiff = currentDate.month - startDate.month;
    final dayDiff = currentDate.day - startDate.day;

    int totalMonths = yearDiff * 12 + monthDiff;

    // 일자가 시작일보다 이전이면 1개월 차감
    if (dayDiff < 0) {
      totalMonths = (totalMonths - 1).clamp(0, double.infinity).toInt();
    }

    return totalMonths;
  }

  // 남은 상환 금액 계산
  double _calculateRemainingAmount(Loan loan, int elapsedMonths) {
    final totalMonths = loan.term;
    final monthlyPrincipal = loan.amount / totalMonths; // 월 원금

    // 경과 개월 수에 따라 상환된 원금 계산
    final paidPrincipal = monthlyPrincipal * elapsedMonths;

    // 남은 원금
    final remainingPrincipal = loan.amount - paidPrincipal;

    // 상환 방식에 따른 추가 계산 (간단한 구현)
    switch (loan.repaymentType) {
      case RepaymentType.equalInstallment:
        // 원리금균등상환: 원금 + 이자
        final monthlyInterest = (loan.amount * loan.interestRate / 100) / 12;
        final totalMonthlyPayment = monthlyPrincipal + monthlyInterest;
        final totalPaid = totalMonthlyPayment * elapsedMonths;
        return (loan.amount + (loan.amount * loan.interestRate / 100)) -
            totalPaid;

      case RepaymentType.equalPrincipal:
        // 원금균등상환: 원금만 균등
        return remainingPrincipal;

      case RepaymentType.bulletPayment:
        // 만기일시상환: 원금은 만기에, 이자만 월별
        final monthlyInterest = (loan.amount * loan.interestRate / 100) / 12;
        final totalInterestPaid = monthlyInterest * elapsedMonths;
        return loan.amount - totalInterestPaid;
    }
  }

  Widget _buildProgressSection(Loan loan, Color color) {
    final now = DateTime.now();
    double progress = 0.0;
    String progressText = '';
    String detailText = '';

    if (loan.startDate.isAfter(now)) {
      // 시작 전
      progress = 0.0;
      progressText = '시작 전';
      detailText = 'D-Day까지 ${loan.getRemainingDays(now)}일 남음';
    } else {
      // 시작 후 - 상환 진행률 계산 (원금 기준)
      final elapsedMonths = _calculateElapsedMonths(loan.startDate, now);
      final totalMonths = loan.term;

      // 상환 방식에 따른 진행률 계산
      progress = (elapsedMonths / totalMonths).clamp(0.0, 1.0);

      if (progress >= 1.0) {
        progressText = '100% 완료';
        detailText = '상환 완료!';
      } else {
        final remainingMonths = totalMonths - elapsedMonths;
        final remainingAmount = _calculateRemainingAmount(loan, elapsedMonths);
        progressText = '${(progress * 100).toStringAsFixed(1)}% 완료';
        detailText = '${formatCurrency(remainingAmount)} 남음';
      }
    }

    return Column(
      children: [
        // 진행률 텍스트
        Text(
          progressText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // 프로그레스 바
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // 배경 프로그레스 바
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // 진행 프로그레스 바
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: MediaQuery.of(context).size.width * 0.6 * progress,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // 달리는 사람 아이콘 (프로그레스 바 안에서 움직임)
              Positioned(
                left: (MediaQuery.of(context).size.width * 0.6 * progress) - 12,
                top: 0,
                child: AnimatedBuilder(
                  animation: _runningAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.directions_run, color: color, size: 16),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 상세 정보
        Text(
          detailText,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // 남은 기간 정보
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '시작일: ${_formatDate(loan.startDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '만료일: ${_formatDate(loan.startDate.add(Duration(days: loan.term * 30)))}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
