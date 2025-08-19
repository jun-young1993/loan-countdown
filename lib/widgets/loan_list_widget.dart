import 'package:flutter/material.dart';
import 'package:loan_countdown/utills/format_currency.dart';
import 'package:provider/provider.dart';
import '../providers/loan_provider.dart';
import '../models/loan.dart';
import '../screens/loan_detail_screen.dart';

class LoanListWidget extends StatelessWidget {
  const LoanListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        if (loanProvider.loans.isEmpty) {
          return const Center(child: Text('등록된 대출이 없습니다'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: loanProvider.loans.length,
          itemBuilder: (context, index) {
            final loan = loanProvider.loans[index];
            return _buildLoanCard(context, loan);
          },
        );
      },
    );
  }

  Widget _buildLoanCard(BuildContext context, Loan loan) {
    DateTime now = DateTime.now();
    bool isExpired = loan.startDate.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoanDetailScreen(loan: loan),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      loan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isExpired ? '진행중' : '대기중',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      '대출금액',
                      formatCurrency(loan.amount),
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      '연 이율',
                      '${loan.interestRate}%',
                      Icons.percent,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      '기간',
                      '${loan.term}개월',
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'D-Day',
                      _formatDate(loan.startDate),
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      '상환방식',
                      loan.repaymentType.displayName,
                      Icons.payment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // D-Day 상태 표시
              _buildDDayStatus(loan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDDayStatus(Loan loan) {
    DateTime now = DateTime.now();
    Duration difference = loan.startDate.difference(now);

    if (difference.isNegative) {
      // D-Day가 이미 지난 경우
      int daysSinceStart = loan.getDaysSinceStart(now);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'D-Day +$daysSinceStart일 (진행중)',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // D-Day까지 남은 경우
      int days = difference.inDays;
      int hours = difference.inHours % 24;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'D-Day까지 $days일 $hours시간 남음',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
