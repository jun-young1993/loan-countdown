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
    String loanId = loan.id;
    DateTime now = DateTime.now();

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
              id: '${loanId}_month_$month',
              paymentNumber: month,
              paymentDate: DateTime(
                loan.startDate.year,
                loan.startDate.month + month - 1,
                loan.startDate.day,
              ),
              principalAmount: principal,
              interestAmount: interest,
              totalAmount: monthlyPayment,
              remainingBalance: remainingPrincipal > 0 ? remainingPrincipal : 0,
              status: 'PENDING',
              paidAt: null,
              actualPaidAmount: 0.0,
              lateFee: 0.0,
              notes: null,
              createdAt: now,
              updatedAt: now,
              loanId: loanId,
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
              id: '${loanId}_month_$month',
              paymentNumber: month,
              paymentDate: DateTime(
                loan.startDate.year,
                loan.startDate.month + month - 1,
                loan.startDate.day,
              ),
              principalAmount: monthlyPrincipal,
              interestAmount: interest,
              totalAmount: totalPayment,
              remainingBalance: remainingPrincipal > 0 ? remainingPrincipal : 0,
              status: 'PENDING',
              paidAt: null,
              actualPaidAmount: 0.0,
              lateFee: 0.0,
              notes: null,
              createdAt: now,
              updatedAt: now,
              loanId: loanId,
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
              id: '${loanId}_month_$month',
              paymentNumber: month,
              paymentDate: DateTime(
                loan.startDate.year,
                loan.startDate.month + month - 1,
                loan.startDate.day,
              ),
              principalAmount: principal,
              interestAmount: interest,
              totalAmount: totalPayment,
              remainingBalance: remainingPrincipal > 0 ? remainingPrincipal : 0,
              status: 'PENDING',
              paidAt: null,
              actualPaidAmount: 0.0,
              lateFee: 0.0,
              notes: null,
              createdAt: now,
              updatedAt: now,
              loanId: loanId,
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
          totalAmount: payment.totalAmount + adjustment,
        );
      }
    }

    newSchedule.addAll(remainingSchedule);

    return newSchedule;
  }

  /// 총 이자 계산
  static double calculateTotalInterest(List<MonthlyPayment> schedule) {
    return schedule.fold(0.0, (sum, payment) => sum + payment.interestAmount);
  }

  /// 총 상환금 계산
  static double calculateTotalPayment(List<MonthlyPayment> schedule) {
    return schedule.fold(0.0, (sum, payment) => sum + payment.totalAmount);
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
  final String id;
  final int paymentNumber;
  final DateTime paymentDate;
  final double principalAmount;
  final double interestAmount;
  final double totalAmount;
  final double remainingBalance;
  final String status;
  final DateTime? paidAt;
  final double actualPaidAmount;
  final double lateFee;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String loanId;

  MonthlyPayment({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    required this.remainingBalance,
    required this.status,
    this.paidAt,
    required this.actualPaidAmount,
    required this.lateFee,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.loanId,
  });

  MonthlyPayment copyWith({
    String? id,
    int? paymentNumber,
    DateTime? paymentDate,
    double? principalAmount,
    double? interestAmount,
    double? totalAmount,
    double? remainingBalance,
    String? status,
    DateTime? paidAt,
    double? actualPaidAmount,
    double? lateFee,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? loanId,
  }) {
    return MonthlyPayment(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      principalAmount: principalAmount ?? this.principalAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      actualPaidAmount: actualPaidAmount ?? this.actualPaidAmount,
      lateFee: lateFee ?? this.lateFee,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      loanId: loanId ?? this.loanId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentNumber': paymentNumber,
      'paymentDate': paymentDate.toIso8601String(),
      'principalAmount': principalAmount.toStringAsFixed(2),
      'interestAmount': interestAmount.toStringAsFixed(2),
      'totalAmount': totalAmount.toStringAsFixed(2),
      'remainingBalance': remainingBalance.toStringAsFixed(2),
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'actualPaidAmount': actualPaidAmount.toStringAsFixed(2),
      'lateFee': lateFee.toStringAsFixed(2),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'loanId': loanId,
    };
  }

  factory MonthlyPayment.fromJson(Map<String, dynamic> json) {
    return MonthlyPayment(
      id: json['id'] as String,
      paymentNumber: json['paymentNumber'] as int,
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      principalAmount: double.parse(json['principalAmount'] as String),
      interestAmount: double.parse(json['interestAmount'] as String),
      totalAmount: double.parse(json['totalAmount'] as String),
      remainingBalance: double.parse(json['remainingBalance'] as String),
      status: json['status'] as String,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      actualPaidAmount: double.parse(json['actualPaidAmount'] as String),
      lateFee: double.parse(json['lateFee'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      loanId: json['loanId'] as String,
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
