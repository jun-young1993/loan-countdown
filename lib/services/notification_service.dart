import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/loan.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 타임존 초기화
    tz.initializeTimeZones();

    // Android 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 초기화 설정
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 알림 플러그인 초기화
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 채널 설정
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // 대출 납부 알림 채널
    const AndroidNotificationChannel paymentChannel = AndroidNotificationChannel(
      'loan_payment',
      '대출 납부 알림',
      description: '대출 납부일과 관련된 알림',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // 중도금 상환 알림 채널
    const AndroidNotificationChannel prepaymentChannel =
        AndroidNotificationChannel(
      'loan_prepayment',
      '중도금 상환 알림',
      description: '중도금 상환 기회와 관련된 알림',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    // D-Day 알림 채널
    const AndroidNotificationChannel ddayChannel = AndroidNotificationChannel(
      'loan_dday',
      'D-Day 알림',
      description: '대출 시작일과 관련된 알림',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(prepaymentChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(ddayChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 처리 로직
    print('알림이 탭되었습니다: ${response.payload}');
  }

  /// 대출 납부일 알림 스케줄
  Future<void> schedulePaymentNotification(Loan loan, int daysBefore) async {
    if (loan.paymentDay == null) return;

    final now = DateTime.now();
    final nextPaymentDate = _getNextPaymentDate(loan.startDate, loan.paymentDay!);
    
    if (nextPaymentDate.isBefore(now)) return;

    final notificationDate = nextPaymentDate.subtract(Duration(days: daysBefore));
    
    if (notificationDate.isBefore(now)) return;

    await _notifications.zonedSchedule(
      _getPaymentNotificationId(loan.id, nextPaymentDate),
      '대출 납부 알림',
      '${loan.name}의 ${daysBefore}일 후 납부일입니다.',
      tz.TZDateTime.from(notificationDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_payment',
          '대출 납부 알림',
          channelDescription: '대출 납부일과 관련된 알림',
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'payment_${loan.id}_${nextPaymentDate.millisecondsSinceEpoch}',
    );
  }

  /// D-Day 알림 스케줄
  Future<void> scheduleDDayNotification(Loan loan, int daysBefore) async {
    final now = DateTime.now();
    final notificationDate = loan.startDate.subtract(Duration(days: daysBefore));
    
    if (notificationDate.isBefore(now)) return;

    await _notifications.zonedSchedule(
      _getDDayNotificationId(loan.id),
      'D-Day 알림',
      '${loan.name}의 D-Day가 ${daysBefore}일 후입니다.',
      tz.TZDateTime.from(notificationDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_dday',
          'D-Day 알림',
          channelDescription: '대출 시작일과 관련된 알림',
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'dday_${loan.id}',
    );
  }

  /// 중도금 상환 기회 알림 스케줄
  Future<void> schedulePrepaymentNotification(Loan loan) async {
    final now = DateTime.now();
    final daysSinceStart = loan.getDaysSinceStart(now);
    
    // 대출 시작 후 3개월, 6개월, 1년에 중도금 상환 기회 알림
    final prepaymentOpportunities = [90, 180, 365];
    
    for (final days in prepaymentOpportunities) {
      if (daysSinceStart >= days && daysSinceStart < days + 30) {
        final notificationDate = now.add(const Duration(days: 1));
        
        await _notifications.zonedSchedule(
          _getPrepaymentNotificationId(loan.id, days),
          '중도금 상환 기회',
          '${loan.name}의 중도금 상환 기회입니다. 이자를 절약할 수 있어요!',
          tz.TZDateTime.from(notificationDate, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'loan_prepayment',
              '중도금 상환 알림',
              channelDescription: '중도금 상환 기회와 관련된 알림',
              icon: '@mipmap/ic_launcher',
              priority: Priority.defaultPriority,
              importance: Importance.defaultImportance,
              category: AndroidNotificationCategory.reminder,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'prepayment_${loan.id}_$days',
        );
        break; // 한 번만 알림
      }
    }
  }

  /// 모든 대출에 대한 알림 스케줄
  Future<void> scheduleAllLoanNotifications(List<Loan> loans) async {
    for (final loan in loans) {
      // D-Day 알림 (7일 전, 1일 전)
      await scheduleDDayNotification(loan, 7);
      await scheduleDDayNotification(loan, 1);
      
      // 납부일 알림 (7일 전, 1일 전)
      await schedulePaymentNotification(loan, 7);
      await schedulePaymentNotification(loan, 1);
      
      // 중도금 상환 기회 알림
      await schedulePrepaymentNotification(loan);
    }
  }

  /// 특정 대출의 모든 알림 취소
  Future<void> cancelLoanNotifications(String loanId) async {
    // 납부일 알림 취소
    await _notifications.cancel(_getPaymentNotificationId(loanId, DateTime.now()));
    
    // D-Day 알림 취소
    await _notifications.cancel(_getDDayNotificationId(loanId));
    
    // 중도금 상환 알림 취소
    await _notifications.cancel(_getPrepaymentNotificationId(loanId, 90));
    await _notifications.cancel(_getPrepaymentNotificationId(loanId, 180));
    await _notifications.cancel(_getPrepaymentNotificationId(loanId, 365));
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 예약된 알림 목록 조회
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 즉시 알림 표시 (테스트용)
  Future<void> showTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_payment',
          '대출 납부 알림',
          channelDescription: '대출 납부일과 관련된 알림',
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // 헬퍼 메서드들
  int _getPaymentNotificationId(String loanId, DateTime paymentDate) {
    return 'payment_${loanId}_${paymentDate.millisecondsSinceEpoch}'.hashCode;
  }

  int _getDDayNotificationId(String loanId) {
    return 'dday_$loanId'.hashCode;
  }

  int _getPrepaymentNotificationId(String loanId, int days) {
    return 'prepayment_${loanId}_$days'.hashCode;
  }

  DateTime _getNextPaymentDate(DateTime startDate, int paymentDay) {
    final now = DateTime.now();
    DateTime nextDate = DateTime(now.year, now.month, paymentDay);
    
    if (nextDate.isBefore(now)) {
      nextDate = DateTime(now.year, now.month + 1, paymentDay);
    }
    
    return nextDate;
  }
}
