import '../models/loan.dart';

class LoanCalculator {
  /// 원리금 균등 상환 계산
  static double calculateEqualInstallment(Loan loan) {
    double principal = loan.amount;
    double monthlyRate = loan.interestRate / 100 / 12;
    int totalMonths = loan.term;

    if (monthlyRate == 0) {
      return principal / totalMonths;
    }

    double monthlyPayment =
        principal *
        (monthlyRate * pow(1 + monthlyRate, totalMonths)) /
        (pow(1 + monthlyRate, totalMonths) - 1);

    return monthlyPayment;
  }

  /// 원금 균등 상환 계산
  static double calculateEqualPrincipal(Loan loan) {
    double principal = loan.amount;
    int totalMonths = loan.term;

    return principal / totalMonths;
  }

  /// 월별 상환 스케줄 생성
  static List<MonthlyPayment> generatePaymentSchedule(
    Loan loan, {
    int startMonth = 1,
    int limit = 100,
  }) {
    List<MonthlyPayment> schedule = [];
    double remainingPrincipal = loan.amount;
    double monthlyRate = loan.interestRate / 100 / 12;

    switch (loan.repaymentType) {
      case RepaymentType.equalInstallment:
        double monthlyPayment = calculateEqualInstallment(loan);

        for (int month = startMonth; month <= limit; month++) {
          double interest = remainingPrincipal * monthlyRate;
          double principal = monthlyPayment - interest;

          if (month == loan.term) {
            principal = remainingPrincipal; // 마지막 달에는 남은 원금 모두 상환
          }

          if (month > loan.term) {
            break;
          }

          remainingPrincipal -= principal;

          schedule.add(
            MonthlyPayment(
              month: month,
              paymentDate: DateTime(
                loan.startDate.year,
                loan.startDate.month + month,
                loan.startDate.day,
              ),
              principal: principal,
              interest: interest,
              totalPayment: monthlyPayment,
              remainingBalance: remainingPrincipal > 0 ? remainingPrincipal : 0,
            ),
          );
        }
        break;

      case RepaymentType.equalPrincipal:
        double monthlyPrincipal = calculateEqualPrincipal(loan);

        for (int month = startMonth; month <= limit; month++) {
          double interest = remainingPrincipal * monthlyRate;
          double totalPayment = monthlyPrincipal + interest;

          remainingPrincipal -= monthlyPrincipal;

          if (month > loan.term) {
            break;
          }
          schedule.add(
            MonthlyPayment(
              month: month,
              paymentDate: DateTime(
                loan.startDate.year,
                loan.startDate.month + month,
                loan.startDate.day,
              ),
              principal: monthlyPrincipal,
              interest: interest,
              totalPayment: totalPayment,
              remainingBalance: remainingPrincipal > 0 ? remainingPrincipal : 0,
            ),
          );
        }
        break;

      case RepaymentType.bulletPayment:
        for (int month = startMonth; month <= limit; month++) {
          double interest = remainingPrincipal * monthlyRate;
          double principal = month == loan.term ? remainingPrincipal : 0;
          double totalPayment = interest + principal;

          if (month == loan.term) {
            remainingPrincipal = 0;
          }

          if (month > loan.term) {
            break;
          }

          schedule.add(
            MonthlyPayment(
              month: month,
              paymentDate: DateTime(
                loan.startDate.year,
                loan.startDate.month + month,
                loan.startDate.day,
              ),
              principal: principal,
              interest: interest,
              totalPayment: totalPayment,
              remainingBalance: remainingPrincipal > 0 ? remainingPrincipal : 0,
            ),
          );
        }
        break;
    }

    return schedule;
  }

  /// 중도금 상환 후 스케줄 재계산
  static List<MonthlyPayment> recalculateAfterPrepayment(
    Loan loan,
    List<MonthlyPayment> originalSchedule,
    double prepaymentAmount,
    DateTime prepaymentDate,
    PrepaymentType prepaymentType,
  ) {
    // 중도금 상환 시점까지의 스케줄은 유지
    List<MonthlyPayment> newSchedule = [];
    double remainingPrincipal = loan.amount;

    for (var payment in originalSchedule) {
      if (payment.paymentDate.isBefore(prepaymentDate)) {
        newSchedule.add(payment);
        remainingPrincipal = payment.remainingBalance;
      } else {
        break;
      }
    }

    // 중도금 상환 적용
    remainingPrincipal -= prepaymentAmount;

    // 남은 기간 계산
    int remainingMonths = 0;
    for (var payment in originalSchedule) {
      if (payment.paymentDate.isAfter(prepaymentDate)) {
        remainingMonths++;
      }
    }

    // 새로운 대출 조건으로 재계산
    Loan newLoan = loan.copyWith(
      amount: remainingPrincipal,
      term: remainingMonths,
      startDate: prepaymentDate,
    );

    List<MonthlyPayment> remainingSchedule = generatePaymentSchedule(newLoan);

    // 월별 납입금 조정
    if (prepaymentType == PrepaymentType.reduceAmount) {
      // 금액 경감형: 기간은 동일하게, 월 납입금만 감소
      double originalMonthlyPayment = calculateEqualInstallment(loan);
      double newMonthlyPayment = calculateEqualInstallment(newLoan);

      for (int i = 0; i < remainingSchedule.length; i++) {
        var payment = remainingSchedule[i];
        double adjustment = originalMonthlyPayment - newMonthlyPayment;

        remainingSchedule[i] = payment.copyWith(
          totalPayment: payment.totalPayment + adjustment,
        );
      }
    }

    newSchedule.addAll(remainingSchedule);

    return newSchedule;
  }

  /// 총 이자 계산
  static double calculateTotalInterest(List<MonthlyPayment> schedule) {
    return schedule.fold(0.0, (sum, payment) => sum + payment.interest);
  }

  /// 총 상환금 계산
  static double calculateTotalPayment(List<MonthlyPayment> schedule) {
    return schedule.fold(0.0, (sum, payment) => sum + payment.totalPayment);
  }

  /// 이자 절감액 계산 (중도금 상환 시)
  static double calculateInterestSavings(
    List<MonthlyPayment> originalSchedule,
    List<MonthlyPayment> newSchedule,
  ) {
    double originalInterest = calculateTotalInterest(originalSchedule);
    double newInterest = calculateTotalInterest(newSchedule);
    return originalInterest - newInterest;
  }
}

/// 월별 상환 정보
class MonthlyPayment {
  final int month;
  final DateTime paymentDate;
  final double principal;
  final double interest;
  final double totalPayment;
  final double remainingBalance;

  MonthlyPayment({
    required this.month,
    required this.paymentDate,
    required this.principal,
    required this.interest,
    required this.totalPayment,
    required this.remainingBalance,
  });

  MonthlyPayment copyWith({
    int? month,
    DateTime? paymentDate,
    double? principal,
    double? interest,
    double? totalPayment,
    double? remainingBalance,
  }) {
    return MonthlyPayment(
      month: month ?? this.month,
      paymentDate: paymentDate ?? this.paymentDate,
      principal: principal ?? this.principal,
      interest: interest ?? this.interest,
      totalPayment: totalPayment ?? this.totalPayment,
      remainingBalance: remainingBalance ?? this.remainingBalance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'paymentDate': paymentDate.toIso8601String(),
      'principal': principal,
      'interest': interest,
      'totalPayment': totalPayment,
      'remainingBalance': remainingBalance,
    };
  }

  factory MonthlyPayment.fromJson(Map<String, dynamic> json) {
    return MonthlyPayment(
      month: json['month'],
      paymentDate: DateTime.parse(json['paymentDate']),
      principal: json['principal'].toDouble(),
      interest: json['interest'].toDouble(),
      totalPayment: json['totalPayment'].toDouble(),
      remainingBalance: json['remainingBalance'].toDouble(),
    );
  }
}

/// 중도금 상환 유형
enum PrepaymentType {
  reduceAmount, // 금액 경감형: 기간 동일, 월 납입금 감소
  reduceTerm, // 기간 단축형: 월 납입금 동일, 기간 단축
}

/// 수학 함수
double pow(double x, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= x;
  }
  return result;
}
