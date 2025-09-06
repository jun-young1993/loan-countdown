import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_common/constants/juny_constants.dart';
import 'package:flutter_common/flutter_common.dart';
import 'package:flutter_common/network/dio_client.dart';
import 'package:flutter_common/repositories/payment_schedule_repository.dart';
import 'package:flutter_common/state/notice/notice_page_bloc.dart';
import 'package:flutter_common/state/notice_group/notice_group_bloc.dart';
import 'package:flutter_common/state/notice_reply/notice_reply_bloc.dart';
import 'package:flutter_common/state/payment_schedule/payment_schedule_bloc.dart';
import 'package:flutter_common/state/user/user_bloc.dart';
import 'package:flutter_common/state/verification/verification_bloc.dart';
import 'package:flutter_common/state/verification/verification_listener.dart';
import 'package:flutter_common/state/payment_schedule/payment_schedule_page_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loan_countdown/firebase_options.dart';
import 'package:loan_countdown/repositorys/loan_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/loan.dart';
import 'providers/loan_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final adMaster = AdMaster();
  await adMaster.initialize(AdConfig());

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 어댑터 등록 (자동 생성된 파일 사용)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(LoanAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(RepaymentTypeAdapter());
  }

  // Hive 박스 열기
  await Hive.openBox<Loan>('loans');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 알림 서비스 초기화
  await NotificationService().initialize();
  // FCM 토큰 가져오기
  final String? fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('fcmToken: $fcmToken');

  await EasyLocalization.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[FLUTTER ERROR] ${details.exception}');
    debugPrint('[STACKTRACE] ${details.stack}');
  };

  final sharedPreferences = await SharedPreferences.getInstance();

  DioClient dioClient = DioClient(
    baseUrl: JunyConstants.apiBaseUrl,
    debugBaseUrl: JunyConstants.apiBaseUrl,
    useLogInterceptor: true,
    appKey: AppKeys.loanCountdown,
    sharedPreferences: sharedPreferences,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppRepository>(
          create: (context) =>
              AppDefaultRepository(sharedPreferences: sharedPreferences),
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => UserDefaultRepository(
            dioClient: dioClient,
            sharedPreferences: sharedPreferences,
            appKey: AppKeys.loanCountdown,
          ),
        ),
        RepositoryProvider<VerificationRepository>(
          create: (context) => VerificationDefaultRepository(
            dioClient: dioClient,
            appKey: AppKeys.loanCountdown,
          ),
        ),
        RepositoryProvider<NoticeGroupRepository>(
          create: (context) =>
              NoticeGroupDefaultRepository(dioClient: dioClient),
        ),
        RepositoryProvider<NoticeRepository>(
          create: (context) => NoticeDefaultRepository(dioClient: dioClient),
        ),
        RepositoryProvider<NoticeReplyRepository>(
          create: (context) =>
              NoticeReplyDefaultRepository(dioClient: dioClient),
        ),
        RepositoryProvider<LoanRepository>(
          create: (context) => LoanDefaultRepository(dioClient: dioClient),
        ),
        RepositoryProvider<PaymentScheduleRepository>(
          create: (context) =>
              PaymentScheduleDefaultRepository(dioClient: dioClient),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AppConfigBloc(appRepository: context.read<AppRepository>()),
          ),
          BlocProvider(
            create: (context) => UserBloc(
              userRepository: context.read<UserRepository>(),
              fcmToken: fcmToken,
            ),
          ),
          BlocProvider(
            create: (context) => VerificationBloc(
              verificationRepository: context.read<VerificationRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => NoticeGroupBloc(
              noticeGroupRepository: context.read<NoticeGroupRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                NoticeBloc(noticeRepository: context.read<NoticeRepository>()),
          ),
          BlocProvider(
            create: (context) => NoticePageBloc(
              noticeRepository: context.read<NoticeRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => NoticeReplyBloc(
              noticeReplyRepository: context.read<NoticeReplyRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => PaymentSchedulePageBloc(
              paymentScheduleRepository: context
                  .read<PaymentScheduleRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => PaymentScheduleBloc(
              paymentScheduleRepository: context
                  .read<PaymentScheduleRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => LoanSummeryBloc(
              paymentScheduleRepository: context
                  .read<PaymentScheduleRepository>(),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            return EasyLocalization(
              supportedLocales: const [Locale('ko'), Locale('en')],
              path: 'packages/flutter_common/assets/translations',
              fallbackLocale: const Locale('ko'),
              child: const MyApp(),
            );
          },
        ),
      ),
    ),
  );
  // MyApp()
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoanProvider(
        loanRepository: context.read<LoanRepository>(),
        userRepository: context.read<UserRepository>(),
      ),
      child: MaterialApp(
        title: Tr.loan.appTitle.tr(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: MultiBlocListener(
          listeners: [VerificationListener(), NoticeListener()],
          child: const HomeScreen(),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
