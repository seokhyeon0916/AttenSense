import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/presentation/providers/professor_attendance_provider.dart';
import 'package:capston_design/presentation/widgets/app_card.dart';
import 'package:capston_design/presentation/widgets/app_loading_indicator.dart';
import 'package:capston_design/presentation/widgets/app_error.dart';
import 'package:capston_design/presentation/widgets/app_bar_back_button.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/domain/repositories/class_repository.dart';
import 'package:capston_design/core/dependency_injection.dart' as di;

class AttendanceStatisticsScreen extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceStatisticsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AttendanceStatisticsScreen> createState() =>
      _AttendanceStatisticsScreenState();
}

class _AttendanceStatisticsScreenState
    extends State<AttendanceStatisticsScreen> {
  String _selectedClassId = '';
  String _selectedClassName = '';
  final List<Map<String, dynamic>> _classes = [];
  int _selectedWeek = 1; // 선택된 주차
  bool _isLoading = false;
  late final ClassRepository _classRepository;
  List<Map<String, dynamic>> _studentAttendance = [];
  // 출석 상태별로 그룹화된 학생 목록
  Map<String, List<Map<String, dynamic>>> _groupedStudents = {};
  // 활성화된 그룹 (아코디언)
  final Set<String> _expandedGroups = {'present', 'late', 'absent'};

  @override
  void initState() {
    super.initState();

    // 위젯에서 받은 classId와 className을 사용하여 초기화
    _selectedClassId = widget.classId;
    _selectedClassName = widget.className;
    _classRepository = di.sl<ClassRepository>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClasses();
      _loadStudentAttendance();
    });
  }

  // 학생 목록을 출석 상태별로 그룹화
  void _groupStudentsByStatus() {
    _groupedStudents = {'present': [], 'late': [], 'absent': [], 'unknown': []};

    for (var student in _studentAttendance) {
      final status = student['status'] as String? ?? 'unknown';
      _groupedStudents[status]?.add(student);
    }
  }

  // 교수의 수업 목록 가져오기
  Future<void> _loadClasses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        debugPrint('사용자 정보를 불러올 수 없습니다.');
        return;
      }

      // 교수의 수업 목록 가져오기
      final classesResult = await _classRepository.getClassesByProfessorId(
        currentUser.id,
      );

      if (!mounted) return;

      classesResult.fold(
        (failure) {
          debugPrint('수업 목록 조회 실패: ${failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('수업 목록을 불러올 수 없습니다: ${failure.message}')),
          );
        },
        (classList) {
          setState(() {
            _classes.clear();
            // Class 객체를 Map으로 변환하여 _classes 리스트에 추가
            for (final classObj in classList) {
              _classes.add({'id': classObj.id, 'name': classObj.name});
            }

            // 현재 선택된 클래스가 목록에 없으면 첫 번째 클래스 선택
            if (!_classes.any((c) => c['id'] == _selectedClassId) &&
                _classes.isNotEmpty) {
              _selectedClassId = _classes.first['id'] as String;
              _selectedClassName = _classes.first['name'] as String;
              _loadStudentAttendance();
            }
          });
        },
      );

      // provider의 기본 데이터만 로딩 (필요한 상세 통계는 나중에 로드)
      final provider = Provider.of<ProfessorAttendanceProvider>(
        context,
        listen: false,
      );
      await provider.loadBasicClassList(currentUser.id);

      // 현재 선택된 수업의 상세 통계만 로드
      if (_selectedClassId.isNotEmpty) {
        await provider.loadClassDetailStats(_selectedClassId);
      }
    } catch (e) {
      debugPrint('수업 목록 불러오기 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 선택된 수업과 주차에 대한 학생 출석 데이터 가져오기
  Future<void> _loadStudentAttendance() async {
    if (_selectedClassId.isEmpty || !mounted) return;

    setState(() {
      _isLoading = true;
      _studentAttendance = [];
    });

    try {
      final provider = Provider.of<ProfessorAttendanceProvider>(
        context,
        listen: false,
      );

      // provider를 통해 선택된 클래스와 주차에 대한 학생 출석 데이터 불러오기
      final result = await provider.getAttendanceByWeek(
        _selectedClassId,
        _selectedWeek,
      );

      if (!mounted) return;

      setState(() {
        if (result.isNotEmpty) {
          _studentAttendance = result;
          _groupStudentsByStatus(); // 학생을 출석 상태별로 그룹화
        }
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('학생 출석 데이터 불러오기 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('학생 출석 데이터를 불러올 수 없습니다: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 클래스 선택이 변경될 때 호출되는 함수
  void _onClassChanged(String classId) {
    final selectedClass = _classes.firstWhere(
      (c) => c['id'] == classId,
      orElse: () => {'id': classId, 'name': '알 수 없는 수업'},
    );

    setState(() {
      _selectedClassId = classId;
      _selectedClassName = selectedClass['name'] as String;
    });

    // 선택된 수업의 상세 통계 로드 (아직 로드되지 않은 경우)
    final provider = Provider.of<ProfessorAttendanceProvider>(
      context,
      listen: false,
    );
    provider.loadClassDetailStats(classId);

    // 선택된 클래스에 대한 출석 데이터 로드
    _loadStudentAttendance();
  }

  // 주차 선택이 변경될 때 호출되는 함수
  void _onWeekChanged(int week) {
    setState(() {
      _selectedWeek = week;
      // 선택된 주차에 대한 출석 데이터 로드
      _loadStudentAttendance();
    });
  }

  // 그룹 확장/축소 토글
  void _toggleGroup(String status) {
    setState(() {
      if (_expandedGroups.contains(status)) {
        _expandedGroups.remove(status);
      } else {
        _expandedGroups.add(status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('출석 통계 - $_selectedClassName'),
        leading: const AppBarBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudentAttendance,
            tooltip: '데이터 새로고침',
          ),
        ],
      ),
      body: Consumer<ProfessorAttendanceProvider>(
        builder: (context, provider, _) {
          if (_isLoading || provider.isLoading) {
            return const AppLoadingIndicator();
          }

          if (provider.errorMessage.isNotEmpty) {
            return AppError(message: provider.errorMessage);
          }

          return _buildWeeklyStudentAttendance(context, provider);
        },
      ),
    );
  }

  // 주차별 학생 출결 현황 화면
  Widget _buildWeeklyStudentAttendance(
    BuildContext context,
    ProfessorAttendanceProvider provider,
  ) {
    if (_classes.isEmpty) {
      return const Center(child: Text('수업 정보가 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 섹션 - 선택 필터 (강의 및 주차)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.7),
                  AppColors.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 타이틀
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '출석 통계 분석',
                              style: AppTypography.headline3(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '학생들의 출석 현황을 확인하고 통계를 분석할 수 있습니다.',
                              style: AppTypography.small(
                                context,
                              ).copyWith(color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: AppSpacing.md),

                  // 필터 섹션 (강의 및 주차 선택)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 강의 선택
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '강의',
                                  style: AppTypography.small(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(canvasColor: AppColors.primaryColor),
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  dropdownColor: AppColors.primaryColor,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  hint: const Text(
                                    '강의를 선택하세요',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  value:
                                      _classes.isEmpty ||
                                              _selectedClassId.isEmpty
                                          ? null
                                          : _classes.any(
                                            (c) => c['id'] == _selectedClassId,
                                          )
                                          ? _selectedClassId
                                          : null,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  items:
                                      _classes.isEmpty
                                          ? null
                                          : _classes.map((classInfo) {
                                            return DropdownMenuItem<String>(
                                              value: classInfo['id'] as String,
                                              child: Text(
                                                classInfo['name'] as String,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _onClassChanged(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // 주차 선택
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '주차',
                                  style: AppTypography.small(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(canvasColor: AppColors.primaryColor),
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  dropdownColor: AppColors.primaryColor,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  hint: const Text(
                                    '주차 선택',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  value: _selectedWeek,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  items:
                                      List.generate(15, (index) => index + 1)
                                          .map(
                                            (week) => DropdownMenuItem<int>(
                                              value: week,
                                              child: Text(
                                                '$week주차',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _onWeekChanged(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 선택된 과목 및 주차 정보 표시
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: AppColors.primaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedClassName,
                              style: AppTypography.subhead(
                                context,
                              ).copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: AppColors.primaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_selectedWeek주차 출결 현황',
                            style: AppTypography.body(
                              context,
                            ).copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 새로고침 버튼
                IconButton(
                  onPressed: _loadStudentAttendance,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: '데이터 새로고침',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 1. 전체 출석률을 보여주는 원형 프로그레스 바
          _buildAttendanceProgressCard(context),
          const SizedBox(height: AppSpacing.md),

          // 2. 출석 상태별 카드 정보
          _buildAttendanceStatusCards(provider),
          const SizedBox(height: AppSpacing.md),

          // 3. 학생별 출결 목록 (상태별로 그룹화)
          _buildStudentListSection(context),
        ],
      ),
    );
  }

  // 출석 상태별 카드 디자인
  Widget _buildAttendanceStatusCards(ProfessorAttendanceProvider provider) {
    if (_studentAttendance.isEmpty) return const SizedBox.shrink();

    // 출석 상태별 학생 수 계산
    int totalCount = _studentAttendance.length;
    int presentCount = _groupedStudents['present']?.length ?? 0;
    int lateCount = _groupedStudents['late']?.length ?? 0;
    int absentCount = _groupedStudents['absent']?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '출석 상태 요약',
                  style: AppTypography.subhead(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    '출석',
                    presentCount,
                    totalCount,
                    AppColors.successColor,
                    Icons.check_circle_rounded,
                    () => _scrollToGroup('present'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatusCard(
                    '지각',
                    lateCount,
                    totalCount,
                    AppColors.warningColor,
                    Icons.access_time_rounded,
                    () => _scrollToGroup('late'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatusCard(
                    '결석',
                    absentCount,
                    totalCount,
                    AppColors.errorColor,
                    Icons.cancel_rounded,
                    () => _scrollToGroup('absent'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 출석률 원형 프로그레스 바 카드
  Widget _buildAttendanceProgressCard(BuildContext context) {
    if (_studentAttendance.isEmpty) return const SizedBox.shrink();

    int totalCount = _studentAttendance.length;
    int presentCount = _groupedStudents['present']?.length ?? 0;
    int lateCount = _groupedStudents['late']?.length ?? 0;

    // 출석률 계산 (출석 + 지각의 50%)
    double attendanceRate =
        (presentCount + (lateCount * 0.5)) / totalCount * 100;

    // 출석률에 따른 색상 및 등급 설정
    Color progressColor;
    String rateGrade;

    if (attendanceRate >= 90) {
      progressColor = AppColors.successColor;
      rateGrade = '우수';
    } else if (attendanceRate >= 75) {
      progressColor = const Color(0xFF4CAF50);
      rateGrade = '양호';
    } else if (attendanceRate >= 60) {
      progressColor = AppColors.warningColor;
      rateGrade = '주의';
    } else {
      progressColor = AppColors.errorColor;
      rateGrade = '미흡';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '출석률 분석',
                  style: AppTypography.subhead(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 프로그레스 원형 차트와 통계 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 프로그레스 원형 차트
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 배경 원
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // 프로그레스 바
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: attendanceRate / 100,
                        ),
                        duration: const Duration(milliseconds: 1000),
                        builder:
                            (context, value, _) => SizedBox(
                              height: 120,
                              width: 120,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                      ),
                      // 내부 흰색 원
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      // 출석률 텍스트
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${attendanceRate.toStringAsFixed(1)}%',
                            style: AppTypography.headline3(context).copyWith(
                              color: progressColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: progressColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rateGrade,
                              style: AppTypography.small(context).copyWith(
                                color: progressColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 통계 요약 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '출석 세부 통계',
                        style: AppTypography.small(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 출석률 바
                      _buildStatProgressBar(
                        context,
                        '출석',
                        presentCount,
                        totalCount,
                        AppColors.successColor,
                      ),
                      const SizedBox(height: 6),
                      // 지각률 바
                      _buildStatProgressBar(
                        context,
                        '지각',
                        lateCount,
                        totalCount,
                        AppColors.warningColor,
                      ),
                      const SizedBox(height: 6),
                      // 결석률 바
                      _buildStatProgressBar(
                        context,
                        '결석',
                        totalCount - presentCount - lateCount,
                        totalCount,
                        AppColors.errorColor,
                      ),
                      const SizedBox(height: 8),
                      // 요약 정보
                      Row(
                        children: [
                          _buildDetailStatChip(
                            context,
                            '총 학생',
                            '$totalCount명',
                            Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          _buildDetailStatChip(
                            context,
                            '참여',
                            '${presentCount + lateCount}명',
                            AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 통계 요약 칩
  Widget _buildDetailStatChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.small(context).copyWith(color: color),
          ),
          Text(
            value,
            style: AppTypography.small(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // 학생 목록 섹션
  Widget _buildStudentListSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 학생 목록 섹션 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '학생별 출석 현황',
                    style: AppTypography.subhead(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '총 ${_studentAttendance.length}명',
                    style: AppTypography.small(
                      context,
                    ).copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 학생 그룹 목록
        _buildGroupedStudentList(context),
      ],
    );
  }

  // 그룹화된 학생 출결 목록
  Widget _buildGroupedStudentList(BuildContext context) {
    if (_studentAttendance.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_late_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '해당 주차의 출석 데이터가 없습니다',
                style: AppTypography.subhead(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '다른 주차를 선택하거나 수업이 진행된 후 다시 확인해주세요.',
                style: AppTypography.small(
                  context,
                ).copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 상태별 제목 매핑
    final statusTitles = {
      'present': '출석 학생',
      'late': '지각 학생',
      'absent': '결석 학생',
      'unknown': '미확인 학생',
    };

    // 상태별 색상 매핑
    final statusColors = {
      'present': AppColors.successColor,
      'late': AppColors.warningColor,
      'absent': AppColors.errorColor,
      'unknown': Colors.grey,
    };

    // 상태별 아이콘 매핑
    final statusIcons = {
      'present': Icons.check_circle_rounded,
      'late': Icons.access_time_rounded,
      'absent': Icons.cancel_rounded,
      'unknown': Icons.help_rounded,
    };

    // 상태별 순서 (출석, 지각, 결석, 미확인 순)
    final sortOrder = ['present', 'late', 'absent', 'unknown'];

    // 상태별로 정렬된 항목 가져오기
    final sortedEntries =
        _groupedStudents.entries.toList()
          ..sort((a, b) => sortOrder.indexOf(a.key) - sortOrder.indexOf(b.key));

    return Column(
      children: [
        // 각 상태별 아코디언 그룹
        for (final entry in sortedEntries)
          if (entry.value.isNotEmpty)
            _buildStudentGroup(
              context,
              entry.key,
              statusTitles[entry.key] ?? '기타',
              entry.value,
              statusColors[entry.key] ?? Colors.grey,
              statusIcons[entry.key] ?? Icons.person,
            ),
      ],
    );
  }

  // 학생 그룹 아코디언
  Widget _buildStudentGroup(
    BuildContext context,
    String status,
    String title,
    List<Map<String, dynamic>> students,
    Color color,
    IconData icon,
  ) {
    final isExpanded = _expandedGroups.contains(status);
    final percentage = (students.length / _studentAttendance.length * 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            // 그룹 헤더 (탭 가능)
            InkWell(
              onTap: () => _toggleGroup(status),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: isExpanded ? Radius.zero : const Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.subhead(context).copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${students.length}명 (${percentage.toStringAsFixed(1)}%)',
                            style: AppTypography.small(
                              context,
                            ).copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '상세 보기',
                            style: AppTypography.small(context).copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: color,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 확장된 경우에만 학생 목록 표시
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    const Divider(height: 1, thickness: 1),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: students.length,
                      separatorBuilder:
                          (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      itemBuilder: (context, index) {
                        final student = students[index];

                        // 체크인 시간 표시
                        final String checkTime =
                            student['checkTime'] != null
                                ? student['checkTime'] as String
                                : '-';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            children: [
                              // 학생 아바타
                              _buildStudentAvatar(
                                student['name'] as String,
                                color,
                              ),
                              const SizedBox(width: 12),

                              // 학생 정보
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'] as String,
                                      style: AppTypography.body(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (student['studentId'] != null)
                                      Text(
                                        student['studentId'] as String,
                                        style: AppTypography.small(
                                          context,
                                        ).copyWith(color: Colors.grey.shade600),
                                      ),
                                  ],
                                ),
                              ),

                              // 체크인 시간
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      checkTime,
                                      style: AppTypography.small(
                                        context,
                                      ).copyWith(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 학생 아바타 위젯
  Widget _buildStudentAvatar(String name, Color backgroundColor) {
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor.withOpacity(0.7), backgroundColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // 통계 프로그레스 바
  Widget _buildStatProgressBar(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.small(context)),
            Text(
              '${percentage.toStringAsFixed(1)}% ($count명)',
              style: AppTypography.small(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // 출석 상태 카드 위젯
  Widget _buildStatusCard(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 아이콘과 라벨
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.small(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 숫자와 백분율
            Text(
              '$count명',
              style: AppTypography.headline3(
                context,
              ).copyWith(fontWeight: FontWeight.bold, color: color),
            ),

            // 프로그레스 바
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: color.withOpacity(0.1),
                color: color,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),

            // 백분율
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTypography.small(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // 특정 그룹으로 스크롤 (미구현 - 실제 구현 시 스크롤 컨트롤러 필요)
  void _scrollToGroup(String status) {
    _toggleGroup(status); // 해당 그룹 펼치기
    // 실제 구현에서는 해당 위치로 스크롤
  }
}
