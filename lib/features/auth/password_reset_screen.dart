import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/services/auth_provider.dart';
import 'package:capston_design/domain/entities/user.dart';
import 'package:capston_design/widgets/app_button.dart';
import 'package:capston_design/widgets/app_text_field.dart';
import 'package:capston_design/widgets/app_loading_indicator.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (success && mounted) {
        setState(() {
          _resetEmailSent = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? '비밀번호 재설정 이메일 전송에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child:
                    _resetEmailSent
                        ? _buildSuccessUI()
                        : _buildFormUI(authProvider),
              ),
            ),
          ),
          if (authProvider.isLoading)
            const AppFullScreenLoading(message: '이메일 전송 중...'),
        ],
      ),
    );
  }

  Widget _buildFormUI(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '비밀번호 재설정',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '가입시 사용한 이메일 주소를 입력하시면 비밀번호 재설정 링크를 보내드립니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: '이메일',
            hintText: 'your.email@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return '유효한 이메일 주소를 입력해주세요';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onEditingComplete: _resetPassword,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: '재설정 링크 전송',
            isLoading: authProvider.isLoading,
            isFullWidth: true,
            onPressed: _resetPassword,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('로그인 화면으로 돌아가시겠습니까?'),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('로그인하기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          '이메일이 전송되었습니다',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '비밀번호 재설정 링크가 이메일로 전송되었습니다. 이메일을 확인하고 링크를 클릭하여 비밀번호를 재설정해주세요.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(
          text: '로그인 화면으로 돌아가기',
          isFullWidth: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
