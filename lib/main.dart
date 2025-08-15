import 'package:flutter/material.dart';
import 'package:flutter_common/constants/juny_constants.dart';
import 'package:flutter_common/network/dio_client.dart';
import 'package:flutter_common/providers/index.dart';
import 'package:flutter_common/repositories/app_repository.dart';
import 'package:flutter_common/repositories/app_reward_repository.dart';
import 'package:flutter_common/repositories/notice_group_repository.dart';
import 'package:flutter_common/repositories/notice_reply_repository.dart';
import 'package:flutter_common/repositories/notice_repository.dart';
import 'package:flutter_common/repositories/user_repository.dart';
import 'package:flutter_common/repositories/verification_repository.dart';
import 'package:flutter_common/state/app_config/app_config_bloc.dart';
import 'package:flutter_common/state/notice/notice_bloc.dart';
import 'package:flutter_common/state/notice/notice_page_bloc.dart';
import 'package:flutter_common/state/notice_group/notice_group_bloc.dart';
import 'package:flutter_common/state/notice_reply/notice_reply_bloc.dart';
import 'package:flutter_common/state/user/user_bloc.dart';
import 'package:flutter_common/state/verification/verification_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/loan.dart';
import 'providers/loan_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 알림 서비스 초기화
  await NotificationService().initialize();

  final sharedPreferences = await SharedPreferences.getInstance();

  DioClient dioClient = DioClient(
    baseUrl: JunyConstants.apiBaseUrl,
    debugBaseUrl: JunyConstants.apiBaseUrl,
    useLogInterceptor: false,
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AppConfigBloc(appRepository: context.read<AppRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                UserBloc(userRepository: context.read<UserRepository>()),
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
        ],
        child: const MyApp(),
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
      create: (context) => LoanProvider(),
      child: MaterialApp(
        title: '대출 D-Day & 상환 추적',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
