import 'package:flutter_common/common_il8n.dart';
import 'package:flutter_common/flutter_common.dart';
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
  int term;
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
    required this.term,
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
      return DateTime(currentDate.year, currentDate.month + 1, startDate.day);
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
      startDate.month + term,
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
    int? term,
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
      term: term ?? this.term,
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
      'term': term,
      'startDate': startDate.toIso8601String(),
      'repaymentType': repaymentType.value,
      'initialPayment': initialPayment,
      'paymentDay': paymentDay,
      'preferentialRates': preferentialRates,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    final id = json['id'];

    final name = json['name'];

    final amount = _parseDouble(json['amount']);

    final interestRate = _parseDouble(json['interestRate']);

    final term = _parseInt(json['term']);

    final repaymentType = RepaymentType.values.firstWhere(
      (e) => e.value == json['repaymentType'],
    );

    final startDate = DateTime.parse(json['startDate']);

    final endDate = json['endDate'] != null
        ? DateTime.parse(json['endDate'])
        : DateTime.now();

    final paymentDay = _parseInt(json['paymentDay']);

    final initialPayment = _parseDouble(json['initialPayment']);

    final preferentialRate = _parseDouble(json['preferentialRate']);

    final preferentialReason = json['preferentialReason']?.toString();

    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now();

    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now();

    return Loan(
      id: json['id'],
      name: json['name'],
      amount: _parseDouble(json['amount']) ?? 0,
      interestRate: _parseDouble(json['interestRate']) ?? 0,
      term: _parseInt(json['term']) ?? 0,
      startDate: DateTime.parse(json['startDate']),
      repaymentType: repaymentType,
      initialPayment: _parseDouble(json['initialPayment']),
      paymentDay: _parseInt(json['paymentDay']),
      preferentialRates: json['preferentialRates'] != null
          ? List<String>.from(json['preferentialRates'])
          : null,
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
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
  String get value {
    switch (this) {
      case RepaymentType.equalInstallment:
        return 'EQUAL_INSTALLMENT';
      case RepaymentType.equalPrincipal:
        return 'EQUAL_PRINCIPAL';
      case RepaymentType.bulletPayment:
        return 'BULLET_PAYMENT';
    }
  }

  // 메소드명을 getRepaymentType으로 변경
  static RepaymentType getRepaymentType(String value) {
    switch (value.toUpperCase()) {
      case 'EQUAL_INSTALLMENT':
        return RepaymentType.equalInstallment;
      case 'EQUAL_PRINCIPAL':
        return RepaymentType.equalPrincipal;
      case 'BULLET_PAYMENT':
        return RepaymentType.bulletPayment;
      default:
        throw ArgumentError('Unknown RepaymentType: $value');
    }
  }

  // 안전한 버전
  static RepaymentType getRepaymentTypeSafe(String value) {
    try {
      return getRepaymentType(value);
    } catch (e) {
      print('⚠️ 알 수 없는 RepaymentType: $value, 기본값 사용');
      return RepaymentType.equalInstallment;
    }
  }

  String get displayName {
    switch (this) {
      case RepaymentType.equalInstallment:
        return Tr.loan.equalPrincipalAndInterestRepayment.tr();
      case RepaymentType.equalPrincipal:
        return Tr.loan.equalPrincipalRepayment.tr();
      case RepaymentType.bulletPayment:
        return Tr.loan.maturityDateRepayment.tr();
    }
  }

  String get description {
    switch (this) {
      case RepaymentType.equalInstallment:
        return Tr.loan.equalPrincipalAndInterestRepaymentDescription.tr();
      case RepaymentType.equalPrincipal:
        return Tr.loan.equalPrincipalRepaymentDescription.tr();
      case RepaymentType.bulletPayment:
        return Tr.loan.maturityDateRepaymentDescription.tr();
    }
  }
}
