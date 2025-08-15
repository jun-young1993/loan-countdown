import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loan_provider.dart';
import '../models/loan.dart';

class LoanDDayWidget extends StatefulWidget {
  const LoanDDayWidget({super.key});

  @override
  State<LoanDDayWidget> createState() => _LoanDDayWidgetState();
}

class _LoanDDayWidgetState extends State<LoanDDayWidget>
    with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // 펄스 애니메이션 초기화
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // 페이드 애니메이션 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    // 애니메이션 시작
    _fadeController.forward();
    _startPulseAnimation();
    
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
    super.dispose();
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        final nextLoan = loanProvider.getNextLoan();
        
        if (nextLoan == null) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildNoLoanCard(),
          );
        }
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildCountdownCard(nextLoan),
        );
      },
    );
  }

  Widget _buildNoLoanCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.schedule,
              size: 48,
              color: Colors.grey[600],
            ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownCard(Loan loan) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withOpacity(0.1),
              cardColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // 대출명과 상태
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: cardColor,
                  size: 24,
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  '${(loan.amount / 10000).toStringAsFixed(1)}만원',
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
                  '${loan.termInMonths}개월',
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

  Widget _buildInfoColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
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
          Text(
            '진행 중',
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }
}
