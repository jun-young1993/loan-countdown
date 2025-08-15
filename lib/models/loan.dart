import 'package:hive/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 0)
class Loan extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  double amount;
  @HiveField(3)
  double interestRate;
  @HiveField(4)
  int termInMonths;
  @HiveField(5)
  DateTime startDate;
  @HiveField(6)
  RepaymentType repaymentType;
  @HiveField(7)
  double? initialPayment;
  @HiveField(8)
  int? paymentDay;
  @HiveField(9)
  List<String>? preferentialRates;
  @HiveField(10)
  DateTime createdAt;
  @HiveField(11)
  DateTime updatedAt;

  Loan({
    required this.id,
    required this.name,
    required this.amount,
    required this.interestRate,
    required this.termInMonths,
    required this.startDate,
    required this.repaymentType,
    this.initialPayment,
    this.paymentDay,
    this.preferentialRates,
  }) : createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  // 대출 잔액 계산
  double getRemainingBalance(DateTime date) {
    // 간단한 구현 - 실제로는 상환 스케줄을 기반으로 계산해야 함
    return amount;
  }

  // 다음 상환일 계산
  DateTime getNextPaymentDate(DateTime currentDate) {
    if (paymentDay == null) {
      // 상환일이 설정되지 않은 경우, D-Day 기준으로 다음 달
      return DateTime(
        currentDate.year,
        currentDate.month + 1,
        startDate.day,
      );
    }

    int nextMonth = currentDate.month + 1;
    int nextYear = currentDate.year;

    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    return DateTime(nextYear, nextMonth, paymentDay!);
  }

  // D-Day 이후 경과일 계산
  int getDaysSinceStart(DateTime currentDate) {
    return currentDate.difference(startDate).inDays;
  }

  // D-Day까지 남은 일수 계산
  int getRemainingDays(DateTime currentDate) {
    Duration difference = startDate.difference(currentDate);
    return difference.inDays;
  }

  // D-Day까지 남은 개월 수 계산
  int getRemainingMonths(DateTime currentDate) {
    DateTime endDate = DateTime(
      startDate.year,
      startDate.month + termInMonths,
      startDate.day,
    );
    return ((endDate.year - currentDate.year) * 12) +
        (endDate.month - currentDate.month);
  }

  // 대출 정보 복사
  Loan copyWith({
    String? id,
    String? name,
    double? amount,
    double? interestRate,
    int? termInMonths,
    DateTime? startDate,
    RepaymentType? repaymentType,
    double? initialPayment,
    int? paymentDay,
    List<String>? preferentialRates,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      termInMonths: termInMonths ?? this.termInMonths,
      startDate: startDate ?? this.startDate,
      repaymentType: repaymentType ?? this.repaymentType,
      initialPayment: initialPayment ?? this.initialPayment,
      paymentDay: paymentDay ?? this.paymentDay,
      preferentialRates: preferentialRates ?? this.preferentialRates,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'interestRate': interestRate,
      'termInMonths': termInMonths,
      'startDate': startDate.toIso8601String(),
      'repaymentType': repaymentType.index,
      'initialPayment': initialPayment,
      'paymentDay': paymentDay,
      'preferentialRates': preferentialRates,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      interestRate: json['interestRate'].toDouble(),
      termInMonths: json['termInMonths'],
      startDate: DateTime.parse(json['startDate']),
      repaymentType: RepaymentType.values[json['repaymentType']],
      initialPayment: json['initialPayment']?.toDouble(),
      paymentDay: json['paymentDay'],
      preferentialRates: json['preferentialRates'] != null
          ? List<String>.from(json['preferentialRates'])
          : null,
    );
  }
}

@HiveType(typeId: 1)
enum RepaymentType {
  @HiveField(0)
  equalInstallment,
  @HiveField(1)
  equalPrincipal,
  @HiveField(2)
  bulletPayment,
}

extension RepaymentTypeExtension on RepaymentType {
  String get displayName {
    switch (this) {
      case RepaymentType.equalInstallment:
        return '원리금균등상환';
      case RepaymentType.equalPrincipal:
        return '원금균등상환';
      case RepaymentType.bulletPayment:
        return '만기일시상환';
    }
  }

  String get description {
    switch (this) {
      case RepaymentType.equalInstallment:
        return '매월 동일한 금액을 납부하는 방식';
      case RepaymentType.equalPrincipal:
        return '매월 동일한 원금과 이자를 납부하는 방식';
      case RepaymentType.bulletPayment:
        return '이자만 납부하고 원금은 만기에 일시 상환하는 방식';
    }
  }
}
