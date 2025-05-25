import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';
import '../main_navigation.dart';
import '../test/server_test_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      print('로그인 시작: 폼 유효성 검사 통과');
      print('입력된 이메일: ${_emailController.text.trim()}');
      print('입력된 비밀번호 길이: ${_passwordController.text.length}');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      print('AuthProvider.signInWithEmailAndPassword 호출 전');
      try {
        print(
          '테스트 계정 정보: professor@test.com / professor123, student@test.com / student123',
        );
        final success = await authProvider.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        print('로그인 결과: $success, 오류메시지: ${authProvider.errorMessage}');
        print('현재 사용자 정보: ${authProvider.currentUser}');

        if (success && mounted) {
          print('로그인 성공: 메인 네비게이션으로 이동');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainNavigation(user: authProvider.currentUser!),
            ),
          );
        } else if (mounted) {
          print('로그인 실패: ${authProvider.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 실패: ${authProvider.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        print('로그인 중 예외 발생: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 중 오류가 발생했습니다: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else {
      print('로그인 실패: 폼 유효성 검사 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 앱 로고
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.wifi,
                      size: 40,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 앱 이름
                  Text(
                    'AttenSense',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // 앱 설명
                  Text(
                    '신뢰할 수 있는 스마트 출결 시스템',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 이메일 입력 필드
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력 필드
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: Validators.validatePassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 8),

                  // 로그인 상태 유지 및 비밀번호 찾기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text('로그인 상태 유지'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PasswordResetScreen(),
                            ),
                          );
                        },
                        child: const Text('비밀번호 찾기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 로그인 버튼
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        authProvider.isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('로그인'),
                  ),
                  const SizedBox(height: 16),

                  // 회원가입 안내
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('계정이 없으신가요?'),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text('회원가입'),
                      ),
                    ],
                  ),

                  // 서버 테스트 화면 버튼 (개발 모드에서만 표시)
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServerTestScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.developer_mode),
                    label: const Text('서버 테스트 화면'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
