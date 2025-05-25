import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
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
                  // 아이콘
                  Icon(
                    _isSent ? Icons.mark_email_read : Icons.lock_reset,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  // 제목
                  Text(
                    _isSent ? '이메일이 발송되었습니다' : '비밀번호 재설정',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 설명
                  Text(
                    _isSent
                        ? '비밀번호 재설정 링크가 이메일로 발송되었습니다. 이메일을 확인해주세요.'
                        : '가입한 이메일 주소를 입력하시면, 비밀번호 재설정 링크를 보내드립니다.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (!_isSent) ...[
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
                    const SizedBox(height: 24),

                    // 재설정 링크 발송 버튼
                    ElevatedButton(
                      onPressed: _sendResetLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('재설정 링크 발송'),
                    ),
                  ] else ...[
                    // 로그인 화면으로 돌아가기 버튼
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('로그인 화면으로 돌아가기'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      // 여기에 비밀번호 재설정 이메일 발송 로직 추가 (미구현)
      // 임시로 성공으로 처리
      setState(() {
        _isSent = true;
      });

      // Scaffold를 통해 스낵바 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('비밀번호 재설정 이메일이 발송되었습니다.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }
}
