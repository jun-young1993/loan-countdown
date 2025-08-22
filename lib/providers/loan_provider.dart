import 'package:flutter/foundation.dart';
import 'package:flutter_common/models/user/user.dart';
import 'package:flutter_common/repositories/user_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loan_countdown/repositorys/loan_repository.dart';
import '../models/loan.dart';
import 'dart:math';

class LoanProvider extends ChangeNotifier {
  late Box<Loan> _loanBox;
  List<Loan> _loans = []; // null 대신 빈 리스트로 초기화
  final LoanRepository _loanRepository;
  final UserRepository _userRepository;

  // 초기화 상태 추적
  bool _isInitialized = false;

  List<Loan> get loans {
    // _loans가 null이거나 초기화되지 않은 경우 빈 리스트 반환
    if (!_isInitialized || _loans == null) {
      return [];
    }
    return _loans;
  }

  bool get isInitialized => _isInitialized;

  LoanProvider({
    required LoanRepository loanRepository,
    required UserRepository userRepository,
  }) : _loanRepository = loanRepository,
       _userRepository = userRepository;

  // Hive 박스 초기화
  Future<void> initializeBox() async {
    try {
      _loanBox = Hive.box<Loan>('loans');
      await _loadLoans();
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Hive 박스 초기화 오류: $e');
      }
      // 에러 발생 시에도 기본값 설정
      _loans = [];
      _isInitialized = true; // 초기화 완료로 표시하여 UI가 멈추지 않도록 함
      notifyListeners();
    }
  }

  // Future<void> loadSchedule(
  //   Loan loan, {
  //   required int skip,
  //   required int take,
  //   required String order,
  // }) async {
  //   try {
  //     _schedule = await _loanRepository.findSchedule(
  //       loan,
  //       skip: skip,
  //       take: take,
  //       order: order,
  //     );
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('대출 상환 계획 로드 오류: $e');
  //     }
  //   }
  // }

  // 대출 목록 로드
  Future<void> _loadLoans() async {
    try {
      final user = await _userRepository.getUserInfo();
      final newLoans = await _loanRepository.findAll(user);

      // 상태 변경을 더 안전하게 처리
      _loans = newLoans;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('대출 목록 로드 오류: $e');
      }
      // 에러 발생 시에도 기존 리스트를 유지 (빈 리스트가 아닌 경우)
      // _loans = []; // 이 줄을 제거하여 기존 데이터 유지
      notifyListeners();
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
      rethrow; // 에러를 상위로 전파
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
      rethrow;
    }
  }

  // 대출 삭제
  Future<void> deleteLoan(Loan loan) async {
    try {
      // await loan.delete();
      await _loanRepository.deleteLoan(loan);
      await _loadLoans();
    } catch (e) {
      if (kDebugMode) {
        print('대출 삭제 오류: $e');
      }
      rethrow;
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
        'totalInterest': 0.0,
        'activeLoans': 0,
        'expiredLoans': 0,
      };
    }

    double totalAmount = _loans.fold(0.0, (sum, loan) => sum + loan.amount);

    // 간단한 이자 계산 (실제로는 상환 스케줄 기반으로 계산해야 함)
    double totalInterest = _loans.fold(0.0, (sum, loan) {
      // 연 이자율을 월 이자율로 변환하여 대략적인 이자 계산
      double monthlyRate = loan.interestRate / 100 / 12;
      double monthlyPayment =
          (loan.amount * monthlyRate * pow(1 + monthlyRate, loan.term)) /
          (pow(1 + monthlyRate, loan.term) - 1);
      double totalPayment = monthlyPayment * loan.term;
      return sum + (totalPayment - loan.amount);
    });

    int activeLoans = getActiveLoans().length;
    int expiredLoans = getExpiredLoans().length;

    return {
      'totalLoans': _loans.length,
      'totalAmount': totalAmount,
      'totalInterest': totalInterest,
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
