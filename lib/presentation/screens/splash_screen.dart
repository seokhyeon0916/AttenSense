import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 절대 경로와 명시적 타입 지정으로 일관성 있게 사용
import 'package:capston_design/presentation/providers/auth_provider.dart'
    show AuthProvider, AuthStatus;
import 'auth/login_screen.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // AuthProvider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.init();
      }
    });

    // 2초 후 인증 상태 확인 및 화면 이동
    Future.delayed(const Duration(seconds: 2), () {
      // mounted 상태를 확인하여 화면이 아직 존재하는 경우에만 context 사용
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 인증 상태에 따라 화면 이동
      if (authProvider.status == AuthStatus.authenticated &&
          authProvider.currentUser != null) {
        // 현재 사용자 정보를 MainNavigation에 전달
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder:
                (context) => MainNavigation(
                  authProvider: authProvider,
                  user: authProvider.currentUser!,
                ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('SplashScreen 초기화 중 오류 발생: $e');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context);

      // 인증 상태 변경 감지 시 화면 전환
      if (authProvider.status == AuthStatus.authenticated) {
        // 다음 프레임에서 화면 전환 (빌드 사이클 충돌 방지)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAuthAndNavigate();
          }
        });
      } else if (authProvider.status == AuthStatus.unauthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        });
      }

      return Scaffold(
        body: Builder(
          builder: (context) {
            // 스플래시 화면 UI
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 앱 로고 또는 아이콘
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.wifi,
                      size: 60,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 앱 이름
                  Text(
                    'AttenSense',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 앱 설명
                  Text(
                    '신뢰할 수 있는 스마트 출결 시스템',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 로딩 인디케이터
                  if (authProvider.status == AuthStatus.loading ||
                      authProvider.status == AuthStatus.initial)
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      // 예외 처리
      print('SplashScreen 빌드 중 오류 발생: $e');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('앱을 초기화하는 중입니다...'),
            ],
          ),
        ),
      );
    }
  }
}
