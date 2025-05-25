import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/dependency_injection.dart' as di;
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/professor_attendance_provider.dart';
import 'presentation/providers/student_attendance_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'services/api_service.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 로케일 데이터 초기화 (날짜 포맷팅을 위해 필요)
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 의존성 주입 초기화
  await di.init();

  // API 서비스 초기화
  await ApiService.init(
    serverUrl: 'https://csi-server-696186584116.asia-northeast3.run.app',
    useServerApi: true,
  );

  // 서버 연결 테스트
  try {
    final healthResponse = await ApiService.checkServerHealth();
    debugPrint('서버 연결 성공: ${healthResponse['status'] ?? '정상'}');
  } catch (e) {
    debugPrint('서버 연결 실패: $e - Firebase 전용 모드로 전환됩니다.');
    // 서버 연결 실패 시 Firebase 전용 모드로 전환
    ApiService.init(useServerApi: false);
  }

  // 싱글톤 인스턴스를 가져와서 직접 전달
  // 예외 처리 추가
  AuthProvider authProvider;
  try {
    authProvider = di.sl<AuthProvider>();
  } catch (e) {
    // GetIt에서 AuthProvider를 찾을 수 없는 경우 새로 생성
    print('GetIt에서 AuthProvider를 가져오는데 실패했습니다: $e');
    print('새로운 AuthProvider 인스턴스를 생성합니다.');
    authProvider = AuthProvider();
    // 싱글톤 등록이 안되어 있다면 등록
    if (!di.sl.isRegistered<AuthProvider>()) {
      di.sl.registerSingleton<AuthProvider>(authProvider);
    }
  }

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 이미 생성된 AuthProvider 인스턴스 사용
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) {
            try {
              return di.sl<ThemeProvider>();
            } catch (e) {
              print('ThemeProvider를 가져오는데 실패했습니다: $e');
              return ThemeProvider();
            }
          },
        ),
        ChangeNotifierProvider<ProfessorAttendanceProvider>(
          create: (_) => ProfessorAttendanceProvider(),
        ),
        ChangeNotifierProvider<StudentAttendanceProvider>(
          create: (_) => StudentAttendanceProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: 'AttenSense',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
            locale: const Locale('ko', 'KR'),
            home: const SplashScreen(),
            themeAnimationDuration: const Duration(milliseconds: 500),
            themeAnimationCurve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
