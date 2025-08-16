import 'package:flutter_common/network/dio_client.dart';
import 'package:flutter_common/models/user/user.dart';
import 'package:flutter_common/repositories/user_repository.dart';
import 'package:loan_countdown/models/loan.dart';

abstract class LoanRepository {
  Future<void> addLoan(Loan loan, User user);
  Future<List<Loan>> findAll(User user);
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
}
