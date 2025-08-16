import 'package:flutter/foundation.dart';
import 'package:flutter_common/models/user/user.dart';
import 'package:flutter_common/repositories/user_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loan_countdown/repositorys/loan_repository.dart';
import '../models/loan.dart';

class LoanProvider extends ChangeNotifier {
  late Box<Loan> _loanBox;
  List<Loan> _loans = [];
  final LoanRepository _loanRepository;
  final UserRepository _userRepository;
  List<Loan> get loans => _loans;

  LoanProvider({
    required LoanRepository loanRepository,
    required UserRepository userRepository,
  }) : _loanRepository = loanRepository,
       _userRepository = userRepository;

  // Hive 박스 초기화
  Future<void> initializeBox() async {
    _loanBox = Hive.box<Loan>('loans');

    await _loadLoans();
  }

  // 대출 목록 로드
  Future<void> _loadLoans() async {
    try {
      final user = await _userRepository.getUserInfo();
      _loans = await _loanRepository.findAll(user);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('대출 목록 로드 오류: $e');
      }
    }
  }

  // 대출 추가
  Future<void> addLoan(Loan loan) async {
    try {
      final user = await _userRepository.getUserInfo();
      await _loanRepository.addLoan(loan, user);
      await _loadLoans();
    } catch (e) {
      if (kDebugMode) {
        print('대출 추가 오류: $e');
      }
    }
  }

  // 대출 수정
  Future<void> updateLoan(Loan loan) async {
    try {
      await loan.save();

      await _loadLoans();
    } catch (e) {
      if (kDebugMode) {
        print('대출 수정 오류: $e');
      }
    }
  }

  // 대출 삭제
  Future<void> deleteLoan(Loan loan) async {
    try {
      await loan.delete();
      await _loadLoans();
    } catch (e) {
      if (kDebugMode) {
        print('대출 삭제 오류: $e');
      }
    }
  }

  // 대출 ID로 조회
  Loan? getLoanById(String id) {
    try {
      return _loans.firstWhere((loan) => loan.id == id);
    } catch (e) {
      return null;
    }
  }

  // D-Day가 가장 가까운 대출 조회
  Loan? getNextLoan() {
    if (_loans.isEmpty) return null;

    DateTime now = DateTime.now();
    Loan? nextLoan;
    int minDays = double.maxFinite.toInt();

    for (var loan in _loans) {
      int daysUntilStart = loan.startDate.difference(now).inDays;
      if (daysUntilStart >= 0 && daysUntilStart < minDays) {
        minDays = daysUntilStart;
        nextLoan = loan;
      }
    }

    return nextLoan;
  }

  // 만료된 대출 목록 조회
  List<Loan> getExpiredLoans() {
    DateTime now = DateTime.now();
    return _loans.where((loan) {
      DateTime endDate = DateTime(
        loan.startDate.year,
        loan.startDate.month + loan.term,
        loan.startDate.day,
      );
      return endDate.isBefore(now);
    }).toList();
  }

  // 활성 대출 목록 조회
  List<Loan> getActiveLoans() {
    DateTime now = DateTime.now();
    return _loans.where((loan) {
      DateTime endDate = DateTime(
        loan.startDate.year,
        loan.startDate.month + loan.term,
        loan.startDate.day,
      );
      return endDate.isAfter(now);
    }).toList();
  }

  // 대출 통계 정보
  Map<String, dynamic> getLoanStatistics() {
    if (_loans.isEmpty) {
      return {
        'totalLoans': 0,
        'totalAmount': 0.0,
        'activeLoans': 0,
        'expiredLoans': 0,
      };
    }

    double totalAmount = _loans.fold(0.0, (sum, loan) => sum + loan.amount);
    int activeLoans = getActiveLoans().length;
    int expiredLoans = getExpiredLoans().length;

    return {
      'totalLoans': _loans.length,
      'totalAmount': totalAmount,
      'activeLoans': activeLoans,
      'expiredLoans': expiredLoans,
    };
  }

  // 대출 검색
  List<Loan> searchLoans(String query) {
    if (query.isEmpty) return _loans;

    return _loans.where((loan) {
      return loan.name.toLowerCase().contains(query.toLowerCase()) ||
          loan.id.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // 대출 정렬
  void sortLoans(String sortBy) {
    switch (sortBy) {
      case 'startDate':
        _loans.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'amount':
        _loans.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'interestRate':
        _loans.sort((a, b) => a.interestRate.compareTo(b.interestRate));
        break;
      case 'name':
        _loans.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        _loans.sort((a, b) => a.startDate.compareTo(b.startDate));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _loanBox.close();
    super.dispose();
  }
}
