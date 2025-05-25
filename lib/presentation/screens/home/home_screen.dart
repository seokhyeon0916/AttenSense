import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/core/utils/animation_utils.dart';
import 'package:capston_design/core/utils/button_utils.dart';
import 'package:capston_design/core/utils/dialog_utils.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/presentation/widgets/skeleton_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/auth_provider.dart';
import '../../providers/professor_attendance_provider.dart';
import '../../providers/student_attendance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/class.dart';
import '../../../domain/repositories/class_repository.dart';
import '../auth/login_screen.dart';
import '../attendance/professor_attendance_screen.dart';
import '../attendance/student_attendance_screen.dart';
import '../attendance/class_selection_screen.dart';
import '../attendance/attendance_detail_screen.dart';
import '../attendance/attendance_statistics_screen.dart';
import '../student/student_attendance_statistics_screen.dart';
import '../notifications/notifications_screen.dart';
import '../main_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final studentAttendanceProvider = Provider.of<StudentAttendanceProvider>(
      context,
    );
    final user = authProvider.currentUser;
    final unreadCount = notificationProvider.unreadCount;

    print(
      'HomeScreen: 현재 사용자 - 이름: ${user?.name}, 역할: ${user?.role}, 교수여부: ${user?.isProfessor}',
    );

    if (user == null) {
      // 사용자가 인증되지 않은 경우 로그인 화면으로 리디렉션
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          AnimationUtils.pageTransition(
            page: const LoginScreen(),
            type: PageTransitionType.fadeAndScale,
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 사용자 역할에 따라 다른 홈 화면 표시
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: studentAttendanceProvider.fetchStudentClasses(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('수강 과목을 불러오는 데 실패했습니다: ${snapshot.error}'),
            ),
          );
        }

        final classes = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              user.isProfessor
                  ? '${user.name} 교수님 환영합니다'
                  : '${user.name}님 환영합니다',
              style: AppTypography.headline3(context),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        AnimationUtils.pageTransition(
                          page: const NotificationsScreen(),
                          type: PageTransitionType.rightToLeft,
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: '알림',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout_outlined),
                tooltip: '로그아웃',
              ),
            ],
          ),
          body:
              user.isProfessor
                  ? _buildProfessorHome(context, user)
                  : _buildStudentHome(context, user, classes),
        );
      },
    );
  }

  // 로그아웃 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    DialogUtils.showConfirmDialog(
      context: context,
      title: '로그아웃',
      message: '정말 로그아웃하시겠습니까?',
      confirmText: '로그아웃',
      cancelText: '취소',
      onConfirm: () {
        // 로그아웃 처리
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.signOut().then((_) {
          Navigator.of(context).pushReplacement(
            AnimationUtils.pageTransition(
              page: const LoginScreen(),
              type: PageTransitionType.fadeAndScale,
            ),
          );
        });
      },
    );
  }

  // 교수 홈 화면
  Widget _buildProfessorHome(BuildContext context, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context, user),
          const SizedBox(height: AppSpacing.md),
          _buildTodayClasses(context),
          const SizedBox(height: AppSpacing.md),
          _buildAttendanceStats(context),
          const SizedBox(height: AppSpacing.md),
          _buildRecentNotifications(context),
        ],
      ),
    );
  }

  // 학생 홈 화면
  Widget _buildStudentHome(
    BuildContext context,
    User user,
    List<Map<String, dynamic>> classes,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context, user),
          const SizedBox(height: AppSpacing.md),
          _buildTodayClasses(context),
          const SizedBox(height: AppSpacing.md),
          _buildMyAttendance(context, classes),
          const SizedBox(height: AppSpacing.md),
          _buildRecentNotifications(context),
        ],
      ),
    );
  }

  // 환영 헤더 위젯
  Widget _buildWelcomeHeader(BuildContext context, User user) {
    final now = DateTime.now();
    String greeting;
    if (now.hour < 12) {
      greeting = '좋은 아침이에요';
    } else if (now.hour < 18) {
      greeting = '안녕하세요';
    } else {
      greeting = '좋은 저녁이에요';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.isProfessor ? '${user.name} 교수님' : '${user.name}님',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘도 화이팅하세요!',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 오늘의 수업 위젯 (즉시 표시형)
  Widget _buildTodayClasses(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isProfessor = user?.isProfessor ?? false;

    if (user == null) {
      return _buildTodayClassesCard(
        context,
        child: _buildErrorState(context, '사용자 정보를 불러올 수 없습니다.'),
      );
    }

    return TodayClassesWidget(user: user, isProfessor: isProfessor);
  }

  // 오늘의 수업 카드 래퍼
  Widget _buildTodayClassesCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 부분
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('오늘의 수업', style: AppTypography.headline3(context)),
                  ],
                ),
                // 새로고침 버튼 추가
                StatefulBuilder(
                  builder: (context, setState) {
                    bool isRefreshing = false;
                    return IconButton(
                      onPressed:
                          isRefreshing
                              ? null
                              : () async {
                                setState(() => isRefreshing = true);

                                try {
                                  // 즉시 새로고침 스낵바 표시
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('새로고침 중...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );

                                  // 500ms 후 화면 재빌드
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  );

                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const HomeScreen(),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isRefreshing = false);
                                  }
                                }
                              },
                      icon:
                          isRefreshing
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.refresh, size: 20),
                      tooltip: '새로고침',
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 컨텐츠 부분
          child,
        ],
      ),
    );
  }

  // 오늘의 수업 콘텐츠 빌더
  Widget _buildTodayClassesContent(
    BuildContext context,
    AsyncSnapshot<List<Class>> snapshot,
    bool isProfessor,
  ) {
    // 로딩 상태
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState(context);
    }

    // 오류 상태
    if (snapshot.hasError) {
      return _buildErrorState(context, snapshot.error.toString());
    }

    // 데이터가 있는 경우
    if (snapshot.hasData) {
      return _buildClassList(context, snapshot.data!, isProfessor);
    }

    // 기본 상태 (데이터 없음)
    return _buildEmptyState(context);
  }

  // 로딩 상태 위젯
  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text('수업 정보를 불러오는 중...', style: AppTypography.body(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '잠시만 기다려주세요 (최대 5초)',
              style: AppTypography.small(context).copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 오류 상태 위젯
  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text('수업 정보를 불러오는 데 실패했습니다', style: AppTypography.subhead(context)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              errorMessage,
              style: AppTypography.small(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, color: Colors.grey, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text('수업없음', style: AppTypography.subhead(context)),
          ],
        ),
      ),
    );
  }

  // 수업 목록 위젯
  Widget _buildClassList(
    BuildContext context,
    List<Class> classes,
    bool isProfessor,
  ) {
    if (classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, color: Colors.grey, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text('수업없음', style: AppTypography.subhead(context)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final classItem = classes[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          title: Text(classItem.name, style: AppTypography.subhead(context)),
          subtitle: Text(
            '${classItem.startTime} - ${classItem.endTime} | ${classItem.location ?? '강의실 미지정'}',
            style: AppTypography.small(
              context,
            ).copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          trailing: AppButton(
            label: isProfessor ? '수업 시작' : '출석하기',
            onPressed: () {
              // 수업 시작/참여 기능
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          isProfessor
                              ? ProfessorAttendanceScreen(
                                classId: classItem.id,
                                className: classItem.name,
                              )
                              : StudentAttendanceScreen(
                                classId: classItem.id,
                                className: classItem.name,
                              ),
                ),
              );
            },
            type: AppButtonType.primary,
            size: AppButtonSize.small,
            icon: isProfessor ? Icons.play_arrow : Icons.check_circle,
          ),
        );
      },
    );
  }

  // 교수용 출석 통계 위젯
  Widget _buildAttendanceStats(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null || !currentUser.isProfessor) {
      return const SizedBox.shrink();
    }

    return AttendanceStatsWidget(professorId: currentUser.id);
  }

  // 학생용 내 출석 위젯
  Widget _buildMyAttendance(
    BuildContext context,
    List<Map<String, dynamic>> classes,
  ) {
    final studentAttendanceProvider = Provider.of<StudentAttendanceProvider>(
      context,
    );
    final myAttendance = studentAttendanceProvider.myAttendance;

    // 통계가 로딩 중이거나 오류인 경우 처리
    if (studentAttendanceProvider.isLoading) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (studentAttendanceProvider.errorMessage.isNotEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text('오류가 발생했습니다', style: AppTypography.subhead(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                studentAttendanceProvider.errorMessage,
                style: AppTypography.small(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed:
                    () => studentAttendanceProvider.refreshMyAttendance(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('과목별 출석 현황', style: AppTypography.headline3(context)),
        const SizedBox(height: AppSpacing.sm),

        // 과목별 출석 현황 카드 목록
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classData = classes[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => AttendanceDetailScreen(
                            classId: classData['id'] as String,
                            className: classData['name'] as String,
                          ),
                    ),
                  );
                },
                child: _buildClassAttendanceCard(
                  context,
                  classData['name'] as String,
                  classData['color'] as Color,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 과목별 출석 카드 위젯
  Widget _buildClassAttendanceCard(
    BuildContext context,
    String className,
    Color color,
  ) {
    final studentAttendanceProvider = Provider.of<StudentAttendanceProvider>(
      context,
    );
    final attendanceCounts = studentAttendanceProvider
        .getAttendanceCountsByClass(className);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.school, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(className, style: AppTypography.subhead(context)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttendanceCount(
                        context,
                        '출석',
                        attendanceCounts['출석']!,
                        AppColors.successColor,
                      ),
                      _buildAttendanceCount(
                        context,
                        '지각',
                        attendanceCounts['지각']!,
                        AppColors.warningColor,
                      ),
                      _buildAttendanceCount(
                        context,
                        '결석',
                        attendanceCounts['결석']!,
                        AppColors.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  // 출석 횟수 항목 위젯
  Widget _buildAttendanceCount(
    BuildContext context,
    String label,
    String count,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          count,
          style: AppTypography.subhead(
            context,
          ).copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.small(context)),
      ],
    );
  }

  // 최근 알림 위젯
  Widget _buildRecentNotifications(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    // 알림이 로딩 중이거나 오류인 경우 처리
    if (notifications.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const Icon(Icons.notifications_off, size: 48, color: Colors.grey),
              const SizedBox(height: AppSpacing.sm),
              Text('알림이 없습니다', style: AppTypography.body(context)),
            ],
          ),
        ),
      );
    }

    // 최대 2개의 최근 알림만 표시
    final recentNotifications =
        notifications.length > 2 ? notifications.sublist(0, 2) : notifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 알림', style: AppTypography.headline3(context)),
            TextButton(
              onPressed: () {
                // 알림 전체 보기
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child:
              notifications.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('알림이 없습니다')),
                  )
                  : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentNotifications.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final notification = recentNotifications[index];
                      final IconData icon = notification['icon'] as IconData;
                      final String title = notification['title'] as String;
                      final String time = notification['time'] as String;
                      final Color color = notification['color'] as Color;
                      final bool isRead = notification['isRead'] as bool;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight:
                                      isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(time),
                        onTap: () {
                          // 알림 상세 보기로 이동
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                          // 해당 알림 읽음으로 표시
                          notificationProvider.markAsRead(
                            notification['id'] as String,
                          );
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// 오늘의 수업 위젯 (무한로딩 해결)
class TodayClassesWidget extends StatefulWidget {
  final User user;
  final bool isProfessor;

  const TodayClassesWidget({
    super.key,
    required this.user,
    required this.isProfessor,
  });

  @override
  State<TodayClassesWidget> createState() => _TodayClassesWidgetState();
}

class _TodayClassesWidgetState extends State<TodayClassesWidget> {
  List<Class> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 초기에 폴백 데이터 설정
    _classes = _getFallbackClasses();
    _loadTodayClasses();
  }

  // 오늘의 수업 데이터 로드
  Future<void> _loadTodayClasses() async {
    try {
      debugPrint('🔄 오늘의 수업 목록 조회 시작 - 사용자: ${widget.user.name}');

      final firestore = FirebaseFirestore.instance;
      final today = DateTime.now().weekday;
      final weekdayString = _getWeekdayString(today);
      debugPrint('📅 오늘의 요일: $today, 요일 문자열: $weekdayString');

      // Firebase 연결성 테스트
      try {
        await firestore.enableNetwork();
      } catch (e) {
        debugPrint('⚠️ Firebase 네트워크 활성화 실패: $e');
      }

      // 사용자 역할에 따라 쿼리 구성
      Query query;
      if (widget.isProfessor) {
        query = firestore
            .collection('classes')
            .where('professorId', isEqualTo: widget.user.id)
            .limit(20);
      } else {
        query = firestore
            .collection('classes')
            .where('studentIds', arrayContains: widget.user.id)
            .limit(20);
      }

      // 재시도 로직과 함께 쿼리 실행
      QuerySnapshot? snapshot;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          snapshot = await query.get().timeout(
            Duration(seconds: 5 + (retryCount * 2)), // 점진적 타임아웃 증가
            onTimeout: () {
              debugPrint(
                '⏰ Firebase 쿼리 타임아웃 발생 (시도 ${retryCount + 1}/$maxRetries)',
              );
              throw TimeoutException(
                '수업 정보 로딩 시간 초과',
                Duration(seconds: 5 + (retryCount * 2)),
              );
            },
          );
          break; // 성공하면 루프 탈출
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // 최대 재시도 횟수 도달 시 예외 재발생
          }
          debugPrint('❌ 쿼리 실패 (시도 $retryCount/$maxRetries): $e');
          await Future.delayed(Duration(seconds: retryCount)); // 지연 후 재시도
        }
      }

      // snapshot이 null인 경우 처리
      if (snapshot == null) {
        throw Exception('수업 데이터를 가져올 수 없습니다.');
      }

      final classes = <Class>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final schedule = List<Map<String, dynamic>>.from(
            data['schedule'] ?? [],
          );
          if (schedule.isEmpty) continue;

          // 오늘 요일과 일치하는 스케줄만 필터링
          final todaySchedules =
              schedule.where((s) {
                final day = s['day'] as String?;
                return day == weekdayString;
              }).toList();

          if (todaySchedules.isNotEmpty) {
            final todaySchedule = todaySchedules.first;
            final classItem = Class(
              id: doc.id,
              name: data['name'] as String? ?? '이름 없는 수업',
              professorId: data['professorId'] as String? ?? '',
              location: data['location'] as String?,
              weekDay: _parseWeekDay(todaySchedule['day'] as String? ?? '월'),
              startTime: todaySchedule['startTime'] as String? ?? '00:00',
              endTime: todaySchedule['endTime'] as String? ?? '00:00',
              status: ClassStatus.scheduled,
              studentIds: List<String>.from(data['studentIds'] ?? []),
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
            classes.add(classItem);
          }
        } catch (docError) {
          debugPrint('❌ 문서 처리 오류 (${doc.id}): $docError');
          continue;
        }
      }

      debugPrint('✅ 수업 조회 성공 - 수업 수: ${classes.length}');

      if (mounted) {
        setState(() {
          _classes = classes; // 빈 리스트든 실제 데이터든 그대로 설정
          _isLoading = false;
          _errorMessage = null; // 성공했으므로 에러 메시지 없음
        });
      }
    } catch (e) {
      debugPrint('❌ 수업 목록 조회 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _classes = _getFallbackClasses(); // 오류 시에만 샘플 데이터 사용
          _isLoading = false;
          _errorMessage = '실제 데이터를 불러올 수 없어 샘플 데이터를 표시합니다.';
        });
      }
    }
  }

  // 폴백 데이터 생성
  List<Class> _getFallbackClasses() {
    if (widget.isProfessor) {
      return [
        Class(
          id: 'fallback_class_1',
          name: '캡스톤 디자인',
          professorId: widget.user.id,
          location: '강의실 101',
          weekDay: WeekDay.values[DateTime.now().weekday - 1],
          startTime: '09:00',
          endTime: '10:30',
          status: ClassStatus.scheduled,
          studentIds: const [],
          createdAt: DateTime.now(),
        ),
        Class(
          id: 'fallback_class_2',
          name: 'C 프로그래밍',
          professorId: widget.user.id,
          location: '강의실 201',
          weekDay: WeekDay.values[DateTime.now().weekday - 1],
          startTime: '14:00',
          endTime: '15:30',
          status: ClassStatus.scheduled,
          studentIds: const [],
          createdAt: DateTime.now(),
        ),
      ];
    } else {
      return [
        Class(
          id: 'fallback_class_1',
          name: '캡스톤 디자인',
          professorId: 'sample_professor',
          location: '강의실 101',
          weekDay: WeekDay.values[DateTime.now().weekday - 1],
          startTime: '09:00',
          endTime: '10:30',
          status: ClassStatus.scheduled,
          studentIds: [widget.user.id],
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  // 요일 문자열 변환
  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  // WeekDay 파싱
  WeekDay _parseWeekDay(String dayStr) {
    switch (dayStr) {
      case '월':
        return WeekDay.monday;
      case '화':
        return WeekDay.tuesday;
      case '수':
        return WeekDay.wednesday;
      case '목':
        return WeekDay.thursday;
      case '금':
        return WeekDay.friday;
      case '토':
        return WeekDay.saturday;
      case '일':
        return WeekDay.sunday;
      default:
        return WeekDay.monday;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('오늘의 수업', style: AppTypography.headline3(context)),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadTodayClasses();
                  },
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.refresh, size: 20),
                  tooltip: '새로고침',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 콘텐츠
          if (_isLoading && _classes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_classes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.event_busy, color: Colors.grey, size: 48),
                    const SizedBox(height: AppSpacing.sm),
                    Text('수업없음', style: AppTypography.subhead(context)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // 상태 메시지
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.all(AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.small(
                              context,
                            ).copyWith(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 수업 목록
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _classes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final classItem = _classes[index];
                    final isRealData = _errorMessage == null;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              isRealData
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isRealData
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              classItem.name,
                              style: AppTypography.subhead(context).copyWith(
                                color: isRealData ? null : Colors.grey,
                              ),
                            ),
                          ),
                          if (!isRealData)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '샘플',
                                style: AppTypography.small(
                                  context,
                                ).copyWith(color: Colors.orange, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${classItem.startTime} - ${classItem.endTime} | ${classItem.location ?? '강의실 미지정'}',
                        style: AppTypography.small(context).copyWith(
                          color:
                              isRealData
                                  ? Theme.of(context).textTheme.bodySmall?.color
                                  : Colors.grey,
                        ),
                      ),
                      trailing: AppButton(
                        label: widget.isProfessor ? '수업 시작' : '출석하기',
                        onPressed:
                            isRealData
                                ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              widget.isProfessor
                                                  ? ProfessorAttendanceScreen(
                                                    classId: classItem.id,
                                                    className: classItem.name,
                                                  )
                                                  : StudentAttendanceScreen(
                                                    classId: classItem.id,
                                                    className: classItem.name,
                                                  ),
                                    ),
                                  );
                                }
                                : null,
                        type: AppButtonType.primary,
                        size: AppButtonSize.small,
                        icon:
                            widget.isProfessor
                                ? Icons.play_arrow
                                : Icons.check_circle,
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// 출석 통계 위젯 (무한루프 해결)
class AttendanceStatsWidget extends StatefulWidget {
  final String professorId;

  const AttendanceStatsWidget({super.key, required this.professorId});

  @override
  State<AttendanceStatsWidget> createState() => _AttendanceStatsWidgetState();
}

class _AttendanceStatsWidgetState extends State<AttendanceStatsWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    // initState에서 안전하게 Provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfessorAttendanceProvider>(
        context,
        listen: false,
      );
      provider.loadBasicClassList(widget.professorId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessorAttendanceProvider>(
      builder: (context, professorAttendanceProvider, child) {
        final attendanceStats = professorAttendanceProvider.attendanceStats;

        // 통계가 로딩 중이거나 오류인 경우 처리
        if (professorAttendanceProvider.isLoading) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.sm),
                  Text('출석 통계를 불러오는 중...', style: AppTypography.body(context)),
                ],
              ),
            ),
          );
        }

        if (professorAttendanceProvider.errorMessage.isNotEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: AppSpacing.sm),
                  Text('오류가 발생했습니다', style: AppTypography.subhead(context)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    professorAttendanceProvider.errorMessage,
                    style: AppTypography.small(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      professorAttendanceProvider.refreshAttendanceStats(
                        widget.professorId,
                      );
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        return AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('출석 통계', style: AppTypography.headline3(context)),
                    IconButton(
                      onPressed: () {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final currentUser = authProvider.currentUser;

                        if (currentUser != null && currentUser.isProfessor) {
                          // 교수용 출석 통계 화면으로 이동
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => const AttendanceStatisticsScreen(
                                    classId: 'default', // 화면에서 자동으로 첫 번째 수업 선택
                                    className: '전체 수업',
                                  ),
                            ),
                          );
                        } else {
                          // 학생용 출석 통계 화면으로 이동
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const StudentAttendanceStatisticsScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // 수업 카드들을 수업 개수에 따라 다르게 표시
                if (attendanceStats.isNotEmpty) ...[
                  Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: PageView.builder(
                          controller:
                              attendanceStats.length == 1
                                  ? PageController(
                                    viewportFraction: 0.6,
                                  ) // 1개일 때는 카드 하나만 중앙에
                                  : PageController(
                                    viewportFraction: 0.55,
                                  ), // 2개 이상일 때는 두 카드가 보이도록
                          itemCount: attendanceStats.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final entry = attendanceStats.entries.elementAt(
                              index,
                            );
                            final classData = entry.value;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  final classId =
                                      classData['classId'] as String;
                                  professorAttendanceProvider
                                      .loadClassDetailStats(classId);

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              AttendanceStatisticsScreen(
                                                classId: classId,
                                                className:
                                                    classData['className']
                                                        as String,
                                              ),
                                    ),
                                  );
                                },
                                child: _buildStatCard(
                                  context,
                                  classData['rate'] as String? ?? '-',
                                  classData['className'] as String? ??
                                      '알 수 없는 수업',
                                  classData['color'] as Color? ?? Colors.grey,
                                  isBasicOnly: classData['isBasicOnly'] == true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // 페이지 인디케이터 (2개 이상일 때만 표시)
                      if (attendanceStats.length > 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            attendanceStats.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _currentPage == index
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else
                  // 수업이 없을 때 표시할 메시지
                  SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 140, // 고정 너비로 일관성 유지
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 32,
                                    color: Colors.grey.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '등록된 수업이 없습니다',
                                    style: AppTypography.body(context).copyWith(
                                      color: Colors.grey.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 통계 카드 위젯
  Widget _buildStatCard(
    BuildContext context,
    String value,
    String title,
    Color color, {
    bool isBasicOnly = false,
  }) {
    return SizedBox(
      width: double.infinity, // 전체 너비 차지
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.headline1(context).copyWith(
                        color: isBasicOnly ? Colors.grey : color,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (isBasicOnly)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.small(
                  context,
                ).copyWith(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
