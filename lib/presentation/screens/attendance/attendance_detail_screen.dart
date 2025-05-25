import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/presentation/providers/student_attendance_provider.dart';
import 'package:capston_design/presentation/providers/professor_attendance_provider.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/presentation/widgets/app_card.dart';
import 'package:capston_design/presentation/widgets/charts/attendance_line_chart.dart';
import 'package:capston_design/presentation/widgets/charts/attendance_pie_chart.dart';
import 'package:capston_design/presentation/widgets/charts/attendance_bar_chart.dart';
import 'package:capston_design/presentation/widgets/charts/attendance_timeline_chart.dart';
import 'attendance_statistics_screen.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final String classId;
  final String className;

  const AttendanceDetailScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isProfessor = authProvider.currentUser?.isProfessor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('$className 출석 현황'),
        elevation: 0,
        actions:
            isProfessor
                ? [
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined),
                    onPressed: () => _navigateToStatistics(context),
                    tooltip: '출석 통계',
                  ),
                ]
                : null,
      ),
      body:
          isProfessor
              ? _buildProfessorView(context)
              : _buildStudentView(context),
    );
  }

  void _navigateToStatistics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AttendanceStatisticsScreen(
              classId: classId,
              className: className,
            ),
      ),
    );
  }

  // 교수용 출석 상세 화면
  Widget _buildProfessorView(BuildContext context) {
    // 교수 ID 가져와서 Provider 초기화
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Consumer<ProfessorAttendanceProvider>(
      builder: (context, provider, _) {
        // Provider 초기화 (한 번만 호출)
        if (currentUser != null && currentUser.isProfessor) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.initializeWithProfessorId(currentUser.id);
          });
        }
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              provider.errorMessage,
              style: const TextStyle(color: AppColors.errorColor),
            ),
          );
        }

        final classStats = provider.getClassAttendanceStats(classId);
        if (classStats == null) {
          return const Center(
            child: Text(
              '수업 정보를 찾을 수 없습니다.',
              style: TextStyle(color: AppColors.errorColor),
            ),
          );
        }

        // 주차별 출석률 데이터 가져오기
        final weeklyAttendanceData = provider.getWeeklyAttendanceRateByClass(
          classId,
        );

        // 출석 상태별 학생 수 가져오기
        final attendanceStatusCounts = provider.getAttendanceStatusCountByClass(
          classId,
        );

        return RefreshIndicator(
          onRefresh: provider.refreshAttendanceStats,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // 출석 요약 정보
              _buildProfessorSummary(context, classStats),
              const SizedBox(height: AppSpacing.md),

              // 주차별 출석률 차트
              _buildHeaderTitle(context, '주차별 출석률 추이'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AttendanceLineChart(
                    weeklyData: weeklyAttendanceData,
                    description: '각 주차별 학생들의 출석률 추이를 보여줍니다.',
                    height: 250,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 출석 상태별 학생 수 차트
              _buildHeaderTitle(context, '출석 상태별 학생 수'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Center(
                        child: AttendancePieChart(
                          present: attendanceStatusCounts['present'] ?? 0,
                          late: attendanceStatusCounts['late'] ?? 0,
                          absent: attendanceStatusCounts['absent'] ?? 0,
                          isDoughnut: true,
                          radius: 100,
                          description: '오늘 수업의 출석 상태별 학생 수를 보여줍니다.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 학생 출석 목록 (임시 데이터)
              _buildHeaderTitle(context, '학생별 출석 현황'),
              const SizedBox(height: AppSpacing.sm),
              _buildStudentList(context),
            ],
          ),
        );
      },
    );
  }

  // 학생용 출석 상세 화면
  Widget _buildStudentView(BuildContext context) {
    return Consumer<StudentAttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              provider.errorMessage,
              style: const TextStyle(color: AppColors.errorColor),
            ),
          );
        }

        final weeklyAttendance = provider.getWeeklyAttendanceByClass(classId);

        // 출석 요약 데이터 계산
        final summary = _calculateAttendanceSummary(weeklyAttendance);

        // 주차별 출석률 데이터 가져오기
        final weeklyAttendanceData = provider.getWeeklyAttendanceRateByClass(
          classId,
        );

        return RefreshIndicator(
          onRefresh: provider.refreshMyAttendance,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // 출석 요약 정보
              _buildStudentSummary(context, summary),
              const SizedBox(height: AppSpacing.md),

              // 출석 현황 파이 차트
              _buildHeaderTitle(context, '출석 현황 요약'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: AttendancePieChart(
                      present: summary['present'] ?? 0,
                      late: summary['late'] ?? 0,
                      absent: summary['absent'] ?? 0,
                      isDoughnut: false,
                      radius: 100,
                      description: '$className 수업의 전체 출석 현황을 보여줍니다.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 주차별 출석률 차트
              _buildHeaderTitle(context, '주차별 출석률 추이'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AttendanceLineChart(
                    weeklyData: weeklyAttendanceData,
                    description: '각 주차별 내 출석률 추이를 보여줍니다.',
                    height: 250,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 주차별 출석 타임라인
              _buildHeaderTitle(context, '주차별 출석 기록'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AttendanceTimelineChart(
                    weeklyData: weeklyAttendance,
                    onItemTap: (weekData) {
                      // 주차 아이템 탭 시 상세 정보 표시
                      _showAttendanceDetails(context, weekData);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 교수용 출석 요약 위젯
  Widget _buildProfessorSummary(
    BuildContext context,
    Map<String, dynamic> classStats,
  ) {
    final totalStudents = classStats['totalStudents'] as int;
    final presentStudents = classStats['presentStudents'] as int;
    final rate = classStats['rate'] as String;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출석 요약', style: AppTypography.headline3(context)),
            const SizedBox(height: AppSpacing.sm),
            Text('전체 학생: $totalStudents명'),
            const SizedBox(height: AppSpacing.xs),
            Text('출석 학생: $presentStudents명'),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: double.parse(rate.replaceAll('%', '')) / 100,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.successColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '출석률: $rate',
                style: AppTypography.subhead(context).copyWith(
                  color: AppColors.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 학생 목록 위젯 (임시 데이터)
  Widget _buildStudentList(BuildContext context) {
    final students = [
      {'name': '김학생', 'id': '20201234', 'status': 'present', 'time': '09:05'},
      {'name': '이학생', 'id': '20201235', 'status': 'present', 'time': '09:03'},
      {'name': '박학생', 'id': '20201236', 'status': 'late', 'time': '09:15'},
      {'name': '최학생', 'id': '20201237', 'status': 'absent', 'time': '-'},
      {'name': '정학생', 'id': '20201238', 'status': 'present', 'time': '09:07'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final status = student['status'] as String;

        IconData iconData;
        Color iconColor;
        String statusText;

        switch (status) {
          case 'present':
            iconData = Icons.check_circle;
            iconColor = AppColors.successColor;
            statusText = '출석';
            break;
          case 'late':
            iconData = Icons.watch_later;
            iconColor = AppColors.warningColor;
            statusText = '지각';
            break;
          case 'absent':
            iconData = Icons.cancel;
            iconColor = AppColors.errorColor;
            statusText = '결석';
            break;
          default:
            iconData = Icons.help_outline;
            iconColor = Colors.grey;
            statusText = '미정';
        }

        return AppCard(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(iconData, color: iconColor),
            ),
            title: Text('${student['name']}'),
            subtitle: Text('출석 시간: ${student['time']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Text(
                statusText,
                style: AppTypography.small(context).copyWith(color: iconColor),
              ),
            ),
            onTap: () {
              // 학생 상세 출석 정보 표시 (향후 구현)
            },
          ),
        );
      },
    );
  }

  Widget _buildHeaderTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(title, style: AppTypography.headline3(context)),
    );
  }

  Map<String, int> _calculateAttendanceSummary(
    List<Map<String, dynamic>> weeklyAttendance,
  ) {
    int present = 0;
    int late = 0;
    int absent = 0;
    int future = 0;

    for (final attendance in weeklyAttendance) {
      final status = attendance['status'];

      switch (status) {
        case 'present':
          present++;
          break;
        case 'late':
          late++;
          break;
        case 'absent':
          absent++;
          break;
        case 'future':
          future++;
          break;
      }
    }

    return {
      'present': present,
      'late': late,
      'absent': absent,
      'future': future,
      'total': weeklyAttendance.length,
    };
  }

  // 주차별 출석 상세 정보 다이얼로그
  void _showAttendanceDetails(
    BuildContext context,
    Map<String, dynamic> weekData,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${weekData['week']}주차 출석 정보'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('수업: ${weekData['className']}'),
                const SizedBox(height: 8),
                Text('날짜: ${weekData['date']}'),
                const SizedBox(height: 8),
                Text(
                  '상태: ${weekData['status'] == 'present'
                      ? '출석'
                      : weekData['status'] == 'late'
                      ? '지각'
                      : weekData['status'] == 'absent'
                      ? '결석'
                      : '예정'}',
                ),
                if (weekData['note'] != null && weekData['note'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('비고: ${weekData['note']}'),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  // 학생용 출석 요약 위젯
  Widget _buildStudentSummary(BuildContext context, Map<String, int> summary) {
    final total =
        (summary['present'] ?? 0) +
        (summary['late'] ?? 0) +
        (summary['absent'] ?? 0);
    final present = summary['present'] ?? 0;
    final rate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출석 요약', style: AppTypography.headline3(context)),
            const SizedBox(height: AppSpacing.sm),
            Text('전체 수업: $total회'),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '출석: $present회, 지각: ${summary['late'] ?? 0}회, 결석: ${summary['absent'] ?? 0}회',
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: total > 0 ? present / total : 0,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.successColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '출석률: $rate%',
                style: AppTypography.subhead(context).copyWith(
                  color: AppColors.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
