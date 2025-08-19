import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_common/state/user/user_bloc.dart';
import 'package:flutter_common/state/user/user_event.dart';
import 'package:flutter_common/state/user/user_selector.dart';
import 'package:flutter_common/widgets/ad/ad_master.dart';
import 'package:flutter_common/widgets/ad/ad_open_app.dart';
import 'package:flutter_common/widgets/layout/notice_screen_layout.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:loan_countdown/screens/add_loan_screen.dart';
import 'package:loan_countdown/utills/format_currency.dart';
import 'package:provider/provider.dart';
import '../providers/loan_provider.dart';
import '../models/loan.dart';
import '../widgets/loan_d_day_widget.dart';
import '../widgets/add_loan_button.dart';
import '../widgets/loan_list_widget.dart';
import 'notification_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSortBy = 'dday';
  bool _isLoading = true;
  UserBloc get userBloc => context.read<UserBloc>();
  bool isFloatingActionButtonVisible = true;

  @override
  void initState() {
    super.initState();
    userBloc.add(const UserEvent.initialize());
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        isFloatingActionButtonVisible = _tabController.index < 3;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });

    AdOpenApp(
      adMaster: AdMaster(),
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-4656262305566191/7156139470'
          : 'ca-app-pub-4656262305566191/7323648092',
    ).listenToAppStateChanges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeProvider() async {
    await context.read<LoanProvider>().initializeBox();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '대출 D-Day & 상환 추적',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications),
            tooltip: '알림 설정',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedSortBy = value;
              });
              context.read<LoanProvider>().sortLoans(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'dday',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 8),
                    Text('D-Day 순'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'amount',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 20),
                    SizedBox(width: 8),
                    Text('대출금액 순'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'interest',
                child: Row(
                  children: [
                    Icon(Icons.percent, size: 20),
                    SizedBox(width: 8),
                    Text('이율 순'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'term',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 8),
                    Text('대출기간 순'),
                  ],
                ),
              ),
            ],
            tooltip: '정렬',
            child: const Icon(Icons.sort),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '홈'),
            Tab(text: '대출 목록'),
            Tab(text: '통계'),
            Tab(text: '커뮤니티'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                _buildLoanListTab(),
                _buildStatsTab(),
                UserInfoSelector((user) {
                  if (user == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return NoticeScreenLayout(
                    groupName: 'parking-zone-code-02782',
                    user: user,
                    detailAd: AdMasterWidget(
                      adType: AdType.banner,
                      adUnitId: 'ca-app-pub-4656262305566191/8099310198',
                      androidAdUnitId: 'ca-app-pub-4656262305566191/7046079402',
                      builder: (state, ad) {
                        return state.isLoaded && ad != null
                            ? AdWidget(ad: ad)
                            : const Text('ad loading...');
                      },
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: UserInfoSelector((user) {
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return isFloatingActionButtonVisible
            ? AddLoanButton(user: user)
            : const SizedBox.shrink();
      }),
    );
  }

  Widget _buildHomeTab() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        final loans = loanProvider.loans;

        if (loans.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await loanProvider.initializeBox();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // D-Day 위젯
                LoanDDayWidget(loans: loans),

                // // 빠른 액션 카드
                // _buildQuickActionsCard(),

                // 요약 통계
                _buildSummaryStatsCard(loanProvider),

                // 최근 대출
                _buildRecentLoansCard(loanProvider),

                // 다음 납부일
                _buildNextPaymentCard(loanProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanListTab() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        if (loanProvider.loans.isEmpty) {
          return _buildEmptyState();
        }

        return const LoanListWidget();
      },
    );
  }

  Widget _buildStatsTab() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        if (loanProvider.loans.isEmpty) {
          return _buildEmptyState();
        }

        final stats = loanProvider.getLoanStatistics();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 전체 요약
              _buildStatsOverviewCard(stats),

              // 대출별 상세 통계
              _buildLoanDetailsCard(loanProvider),

              // 상환 진행률
              _buildRepaymentProgressCard(loanProvider),

              // 이자 분석
              _buildInterestAnalysisCard(loanProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '등록된 대출이 없습니다',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '새로운 대출을 추가하여\nD-Day와 상환 일정을 관리해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          UserInfoSelector((user) {
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ElevatedButton.icon(
              onPressed: () {
                // FAB 클릭 효과
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddLoanScreen(user: user),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('첫 번째 대출 추가하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '빠른 액션',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.add,
                      label: '대출 추가',
                      onTap: () {
                        // FAB 클릭 효과
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('오른쪽 하단의 + 버튼을 눌러주세요!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.notifications,
                      label: '알림 설정',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatsCard(LoanProvider loanProvider) {
    final loans = loanProvider.loans;
    final activeLoans = loanProvider.getActiveLoans();
    final expiredLoans = loanProvider.getExpiredLoans();

    final totalAmount = loans.fold(0.0, (sum, loan) => sum + loan.amount);
    final avgInterest = loans.isEmpty
        ? 0.0
        : loans.fold(0.0, (sum, loan) => sum + loan.interestRate) /
              loans.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '요약 통계',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '전체 대출',
                      '${loans.length}건',
                      Icons.account_balance,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '활성 대출',
                      '${activeLoans.length}건',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '만료 대출',
                      '${expiredLoans.length}건',
                      Icons.check_circle,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '총 대출금',
                      formatCurrency(totalAmount),
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '평균 이율',
                      '${avgInterest.toStringAsFixed(2)}%',
                      Icons.percent,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLoansCard(LoanProvider loanProvider) {
    final recentLoans = loanProvider.loans.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.recent_actors,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '최근 추가된 대출',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentLoans.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '아직 대출이 없습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...recentLoans.map((loan) => _buildRecentLoanItem(loan)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLoanItem(Loan loan) {
    final now = DateTime.now();
    final daysUntilStart = loan.startDate.difference(now).inDays;
    final isStarted = daysUntilStart <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatCurrency(loan.amount)} • ${loan.interestRate}%',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isStarted ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isStarted ? '진행중' : 'D-$daysUntilStart',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPaymentCard(LoanProvider loanProvider) {
    final nextLoan = loanProvider.getNextLoan();

    if (nextLoan == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final daysUntilStart = nextLoan.startDate.difference(now).inDays;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '다음 납부일',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextLoan.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(nextLoan.amount),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysUntilStart > 0 ? 'D-$daysUntilStart' : 'D-Day',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverviewCard(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '전체 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '총 대출금',
                    formatCurrency(stats['totalAmount']),
                    Icons.attach_money,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '총 이자',
                    formatCurrency(stats['totalInterest']),
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailsCard(LoanProvider loanProvider) {
    final loans = loanProvider.loans;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '대출별 상세',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...loans.map((loan) => _buildLoanDetailItem(loan)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailItem(Loan loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${loan.interestRate}%',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatCurrency(loan.amount),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              Text(
                '${loan.term}개월',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentProgressCard(LoanProvider loanProvider) {
    // 간단한 진행률 표시
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상환 진행률',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '상환 진행률 기능은\n추후 업데이트 예정입니다',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestAnalysisCard(LoanProvider loanProvider) {
    // 이자 분석 표시
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이자 분석',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '이자 분석 기능은\n추후 업데이트 예정입니다',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
