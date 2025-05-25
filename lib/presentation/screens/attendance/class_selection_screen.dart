import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_button.dart';
import 'package:capston_design/domain/entities/class.dart';
import 'package:capston_design/domain/repositories/class_repository.dart';
import 'package:capston_design/core/dependency_injection.dart' as di;
import 'professor_attendance_screen.dart';
import 'student_attendance_screen.dart';

/// 출석 화면으로 이동하기 전에 수업을 선택하는 화면
class ClassSelectionScreen extends StatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  final ClassRepository _classRepository = di.sl<ClassRepository>();
  List<Class> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 현재 선택된 요일 인덱스 (0: 월요일, 1: 화요일, ...)
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // 현재 요일로 초기 선택 설정
    final now = DateTime.now();
    // DateTime의 weekday는 1(월)~7(일)이므로 0~6으로 변환 (0: 월요일)
    _selectedDayIndex = (now.weekday - 1) % 7;
    _loadClasses();
  }

  // 사용자 역할에 따라 수업 목록 로드
  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '사용자 정보를 불러올 수 없습니다.';
        });
        return;
      }

      // 사용자 역할에 따라 다른 메서드 호출
      final classesResult =
          currentUser.isProfessor
              ? await _classRepository.getClassesByProfessorId(currentUser.id)
              : await _classRepository.getClassesByStudentId(currentUser.id);

      classesResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = '수업 목록을 불러올 수 없습니다: ${failure.message}';
          });
        },
        (classes) {
          setState(() {
            _classes = classes;
            _isLoading = false;

            // 수업이 없는 경우 메시지 설정
            if (_classes.isEmpty) {
              _errorMessage = '등록된 수업이 없습니다.';
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '수업 목록을 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 요일 문자열 변환 헬퍼 함수
  String _getWeekDayString(WeekDay weekDay) {
    switch (weekDay) {
      case WeekDay.monday:
        return '월요일';
      case WeekDay.tuesday:
        return '화요일';
      case WeekDay.wednesday:
        return '수요일';
      case WeekDay.thursday:
        return '목요일';
      case WeekDay.friday:
        return '금요일';
      case WeekDay.saturday:
        return '토요일';
      case WeekDay.sunday:
        return '일요일';
    }
  }

  // WeekDay enum을 인덱스로 변환 (0: 월요일, 1: 화요일, ...)
  int _weekDayToIndex(WeekDay weekDay) {
    switch (weekDay) {
      case WeekDay.monday:
        return 0;
      case WeekDay.tuesday:
        return 1;
      case WeekDay.wednesday:
        return 2;
      case WeekDay.thursday:
        return 3;
      case WeekDay.friday:
        return 4;
      case WeekDay.saturday:
        return 5;
      case WeekDay.sunday:
        return 6;
    }
  }

  // 인덱스를 WeekDay enum으로 변환
  WeekDay _indexToWeekDay(int index) {
    switch (index) {
      case 0:
        return WeekDay.monday;
      case 1:
        return WeekDay.tuesday;
      case 2:
        return WeekDay.wednesday;
      case 3:
        return WeekDay.thursday;
      case 4:
        return WeekDay.friday;
      case 5:
        return WeekDay.saturday;
      case 6:
        return WeekDay.sunday;
      default:
        return WeekDay.monday;
    }
  }

  // 요일별 수업 목록 가져오기
  List<Class> _getClassesByDay(int dayIndex) {
    final weekDay = _indexToWeekDay(dayIndex);
    return _classes.where((classItem) => classItem.weekDay == weekDay).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime)); // 시작 시간 기준 정렬
  }

  // 수업 선택 시 적절한 출석 화면으로 이동
  void _onClassSelected(Class selectedClass) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    if (currentUser.isProfessor) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProfessorAttendanceScreen(
                classId: selectedClass.id,
                className: selectedClass.name,
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => StudentAttendanceScreen(
                classId: selectedClass.id,
                className: selectedClass.name,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수업 선택'), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: AppTypography.headline2(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              AppButton(
                text: '새로고침',
                onPressed: _loadClasses,
                type: ButtonType.secondary,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildDaySelector(), Expanded(child: _buildClassList())],
    );
  }

  // 요일 선택 탭
  Widget _buildDaySelector() {
    final List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          7,
          (index) => _buildDayTab(weekDays[index], index),
        ),
      ),
    );
  }

  // 각 요일 탭
  Widget _buildDayTab(String day, int index) {
    final isSelected = _selectedDayIndex == index;
    final today = DateTime.now().weekday - 1;
    final isToday = today == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDayIndex = index;
        });
      },
      child: Container(
        width: 40,
        height: 60,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryColor
                  : isToday
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: AppTypography.body(context).copyWith(
                fontWeight: FontWeight.bold,
                color:
                    isSelected
                        ? Colors.white
                        : isToday
                        ? AppColors.primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isToday && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 수업 목록
  Widget _buildClassList() {
    final classesByDay = _getClassesByDay(_selectedDayIndex);

    if (classesByDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '${_getWeekDayString(_indexToWeekDay(_selectedDayIndex))}에 등록된 수업이 없습니다.',
              style: AppTypography.body(context).copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classesByDay.length,
      itemBuilder: (context, index) {
        final classItem = classesByDay[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  classItem.name,
                  style: AppTypography.headline3(context),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${classItem.startTime} - ${classItem.endTime}',
                          style: AppTypography.body(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          classItem.location ?? '강의실 정보 없음',
                          style: AppTypography.body(context),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '출석',
                    style: AppTypography.small(context).copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => _onClassSelected(classItem),
              ),
            ],
          ),
        );
      },
    );
  }
}
