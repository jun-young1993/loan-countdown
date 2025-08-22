import 'package:flutter_common/network/dio_client.dart';
import 'package:flutter_common/models/user/user.dart';
import 'package:loan_countdown/models/loan.dart';
import 'package:loan_countdown/services/loan_calculator.dart';

abstract class LoanRepository {
  Future<void> addLoan(Loan loan, User user);
  Future<List<Loan>> findAll(User user);
  Future<List<MonthlyPayment>> findSchedule(
    Loan loan, {
    required int skip,
    required int take,
    required String order,
  });

  Future<void> deleteLoan(Loan loan);
}

class LoanDefaultRepository implements LoanRepository {
  final DioClient dioClient;
  LoanDefaultRepository({required this.dioClient});

  @override
  Future<void> addLoan(Loan loan, User user) async {
    await dioClient.post('/loans', data: {...loan.toJson(), 'userId': user.id});
  }

  @override
  Future<List<Loan>> findAll(User user) async {
    final response = await dioClient.get('/loans/user/${user.id}');
    if (response.statusCode == 200) {
      return (response.data as List<dynamic>)
          .map((e) => Loan.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      '[${response.statusCode}] Failed to fetch loans: ${response.statusMessage ?? 'Unknown error'}',
    );
  }

  @override
  Future<List<MonthlyPayment>> findSchedule(
    Loan loan, {
    required int skip,
    required int take,
    required String order,
  }) async {
    final response = await dioClient.get(
      '/loans/${loan.id}/schedule',
      queryParameters: {'skip': skip, 'take': take, 'order': order},
    );
    if (response.statusCode == 200) {
      return (response.data as List<dynamic>)
          .map((e) => MonthlyPayment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      '[${response.statusCode}] Failed to fetch schedule: ${response.statusMessage ?? 'Unknown error'}',
    );
  }

  @override
  Future<void> deleteLoan(Loan loan) async {
    await dioClient.delete('/loans/${loan.id}');
  }
}
