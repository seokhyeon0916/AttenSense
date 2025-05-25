import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/domain/entities/user.dart'
    show User, UserEntityRole;
import 'package:capston_design/domain/entities/class.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart'
    show AuthProvider, AuthStatus;

// 홈 화면 (대시보드)
import 'home/home_screen.dart';

// 추후 구현될 화면들
import 'schedule/schedule_screen.dart';
import 'profile/profile_screen.dart';
import 'attendance/professor_attendance_screen.dart';
import 'attendance/student_attendance_screen.dart';
import 'auth/login_screen.dart';
import 'attendance/class_selection_screen.dart';

// 전역 키를 사용하여 다른 위젯에서 MainNavigation에 접근할 수 있도록 함
final GlobalKey<_MainNavigationState> mainNavigationKey =
    GlobalKey<_MainNavigationState>();

class MainNavigation extends StatefulWidget {
  // AuthProvider 선택적으로 받기
  final AuthProvider? authProvider;
  final User? user;
  final int initialTab;

  const MainNavigation({
    super.key,
    this.authProvider,
    this.user,
    this.initialTab = 0,
  });

  // 정적 메서드를 통해 외부에서 탭 인덱스 변경 가능
  static void navigateToTab(BuildContext context, int index) {
    mainNavigationKey.currentState?.navigateToTab(index);
  }

  // 정적 메서드를 통해 특정 수업으로 이동
  static void navigateToClass(BuildContext context, Class classItem) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // 사용자 정보가 없으면 로그인 화면으로 이동
    if (user == null) {
      print('navigateToClass: 사용자 정보가 없습니다. 로그인이 필요합니다.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final isProfessor = user.isProfessor;
    print(
      'navigateToClass: ${isProfessor ? "교수" : "학생"} 역할로 ${classItem.name} 수업으로 이동합니다.',
    );

    Navigator.push(
      context,
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
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  // 특정 탭으로 이동하는 함수
  void navigateToTab(int index) {
    if (index >= 0 && index < 4) {
      // 4개의 탭 제한
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      // 직접 전달받은 AuthProvider가 있으면 사용하고, 없으면 Provider.of로 가져옴
      final authProvider =
          widget.authProvider ?? Provider.of<AuthProvider>(context);
      // 직접 전달받은 user가 null이면 provider에서 가져옴
      final user = widget.user ?? authProvider.currentUser;

      print(
        'MainNavigation: 현재 사용자 - 이름: ${user?.name}, 역할: ${user?.role}, 교수여부: ${user?.isProfessor}',
      );

      // 사용자가 null인 경우 로그인 화면으로 리디렉션
      if (user == null) {
        // 인증되지 않은 경우 로그인 화면으로 리디렉션
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // 사용자 역할에 따라 탭 구성을 다르게 설정
      final List<Widget> screens = _getScreensByRole(user);
      final List<BottomNavigationBarItem> navItems = _getNavItemsByRole(user);

      return Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: navItems,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
            showUnselectedLabels: true,
            elevation: 8,
          ),
        ),
      );
    } catch (e) {
      // 예외 처리
      print('MainNavigation 빌드 중 오류 발생: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('오류가 발생했습니다.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('로그인 화면으로 이동'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // 사용자 역할에 따라 화면 목록 반환
  List<Widget> _getScreensByRole(User user) {
    // 기본 화면 구성 (모든 사용자 공통)
    final List<Widget> screens = [
      const HomeScreen(), // 대시보드/홈
      const ScheduleScreen(), // 시간표 관리/시간표
      const ClassSelectionScreen(), // 수업 선택 화면
      const ProfileScreen(), // 프로필
    ];

    return screens;
  }

  // 사용자 역할에 따라 네비게이션 아이템 목록 반환
  List<BottomNavigationBarItem> _getNavItemsByRole(User user) {
    if (user.isProfessor) {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: '대시보드',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '수업관리',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg),
          label: '출석',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
      ];
    } else {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '홈'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '시간표',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg),
          label: '출석',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
      ];
    }
  }
}
