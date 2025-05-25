import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/presentation/providers/theme_provider.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_divider.dart';

import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildAppearanceSettings(context),
          AppSpacing.verticalSpaceMD,
          _buildNotificationSettings(context),
          AppSpacing.verticalSpaceMD,
          _buildAccountSettings(context),
          AppSpacing.verticalSpaceMD,
          _buildAboutSettings(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(title, style: AppTypography.headline3(context)),
    );
  }

  Widget _buildAppearanceSettings(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '화면 설정'),
        AppCard(
          child: Column(
            children: [
              ListTile(
                title: const Text('다크 모드'),
                subtitle: const Text('어두운 테마를 사용하여 눈의 피로를 줄입니다'),
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ),
              const AppDivider(),
              ListTile(
                title: const Text('시스템 설정에 따름'),
                subtitle: const Text('기기의 디스플레이 설정을 따릅니다'),
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.system,
                  onChanged: (value) {
                    if (value) {
                      themeProvider.setThemeMode(ThemeMode.system);
                    } else {
                      themeProvider.setThemeMode(
                        Theme.of(context).brightness == Brightness.dark
                            ? ThemeMode.dark
                            : ThemeMode.light,
                      );
                    }
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '알림 설정'),
        AppCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('수업 시작 알림'),
                subtitle: const Text('수업 시작 5분 전에 알려줍니다'),
                value: true, // 기본값, 나중에 Provider로 관리
                onChanged: (value) {
                  // 알림 설정 변경 로직
                },
                activeColor: AppColors.primaryColor,
              ),
              const AppDivider(),
              SwitchListTile(
                title: const Text('비활동 감지 알림'),
                subtitle: const Text('일정 시간 움직임이 없을 때 알려줍니다'),
                value: true, // 기본값, 나중에 Provider로 관리
                onChanged: (value) {
                  // 알림 설정 변경 로직
                },
                activeColor: AppColors.primaryColor,
              ),
              const AppDivider(),
              SwitchListTile(
                title: const Text('진동'),
                subtitle: const Text('알림 시 진동을 함께 사용합니다'),
                value: true, // 기본값, 나중에 Provider로 관리
                onChanged: (value) {
                  // 진동 설정 변경 로직
                },
                activeColor: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '계정 설정'),
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('비밀번호 변경'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // 비밀번호 변경 화면으로 이동
                  _showChangePasswordDialog(context);
                },
              ),
              const AppDivider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.errorColor),
                title: const Text(
                  '로그아웃',
                  style: TextStyle(color: AppColors.errorColor),
                ),
                onTap: () {
                  _showLogoutConfirmDialog(context, authProvider);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '앱 정보'),
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('버전 정보'),
                subtitle: const Text('AttenSense v1.0.0'),
                onTap: () {
                  // 버전 정보 상세 표시
                },
              ),
              const AppDivider(),
              ListTile(
                leading: const Icon(Icons.policy),
                title: const Text('개인정보처리방침'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // 개인정보처리방침 화면으로 이동
                },
              ),
              const AppDivider(),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('이용약관'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // 이용약관 화면으로 이동
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('비밀번호 변경'),
            content: const Text('이 기능은 아직 개발 중입니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showLogoutConfirmDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  authProvider.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                ),
                child: const Text('로그아웃'),
              ),
            ],
          ),
    );
  }
}
