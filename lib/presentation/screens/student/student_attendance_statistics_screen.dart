import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/student_attendance_provider.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/app_error.dart';
import '../../widgets/app_bar_back_button.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/typography.dart';

class StudentAttendanceStatisticsScreen extends StatefulWidget {
  const StudentAttendanceStatisticsScreen({super.key});

  @override
  State<StudentAttendanceStatisticsScreen> createState() =>
      _StudentAttendanceStatisticsScreenState();
}

class _StudentAttendanceStatisticsScreenState
    extends State<StudentAttendanceStatisticsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentStatistics();
    });
  }

  // 학생 출석 통계 데이터 로드
  Future<void> _loadStudentStatistics() async {
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

      final provider = Provider.of<StudentAttendanceProvider>(
        context,
        listen: false,
      );
      await provider.fetchStudentStatistics(currentUser.id);
    } catch (e) {
      debugPrint('학생 출석 통계 불러오기 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('출석 통계를 불러올 수 없습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 출석 통계'),
        leading: const AppBarBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudentStatistics,
            tooltip: '데이터 새로고침',
          ),
        ],
      ),
      body: Consumer<StudentAttendanceProvider>(
        builder: (context, provider, _) {
          if (_isLoading || provider.isLoading) {
            return const AppLoadingIndicator();
          }

          if (provider.errorMessage.isNotEmpty) {
            return AppError(message: provider.errorMessage);
          }

          return _buildStudentStatistics(context, provider);
        },
      ),
    );
  }

  // 학생 출석 통계 메인 화면
  Widget _buildStudentStatistics(
    BuildContext context,
    StudentAttendanceProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 전체 출석률 프로그레스 카드
          _buildOverallAttendanceCard(provider),
          const SizedBox(height: AppSpacing.md),

          // 2. 출석 상태별 요약 카드
          _buildAttendanceStatusSummary(provider),
          const SizedBox(height: AppSpacing.md),

          // 3. 수업별 출석 현황
          _buildClassAttendanceCards(provider),
          const SizedBox(height: AppSpacing.md),

          // 4. 출석 패턴 분석
          _buildAttendancePattern(provider),
          const SizedBox(height: AppSpacing.md),

          // 5. 최근 출석 기록
          _buildRecentAttendance(provider),
          const SizedBox(height: AppSpacing.md),

          // 6. 학습 목표 달성도
          _buildLearningGoalProgress(provider),
        ],
      ),
    );
  }

  // 전체 출석률 프로그레스 카드
  Widget _buildOverallAttendanceCard(StudentAttendanceProvider provider) {
    final attendanceRate = provider.getOverallAttendanceRate();
    final grade = provider.getAttendanceGrade();
    final recommendation = provider.getRecommendation();
    final color = provider.getAttendanceRateColor(attendanceRate);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.insights_rounded, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '전체 출석률',
                        style: AppTypography.headline3(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '현재 학기 기준',
                        style: AppTypography.small(
                          context,
                        ).copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 출석률 원형 프로그레스
            Row(
              children: [
                // 원형 프로그레스
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: attendanceRate / 100,
                        ),
                        duration: const Duration(milliseconds: 1000),
                        builder:
                            (context, value, _) => SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$attendanceRate%',
                            style: AppTypography.headline2(context).copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              grade,
                              style: AppTypography.small(context).copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),

                // 추천 메시지
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: color,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '피드백',
                              style: AppTypography.small(context).copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation,
                          style: AppTypography.small(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 출석 상태별 요약
  Widget _buildAttendanceStatusSummary(StudentAttendanceProvider provider) {
    final statusCounts = provider.getAttendanceStatusCounts();

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
                  Icons.analytics_outlined,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '출석 상태 요약',
                  style: AppTypography.subhead(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCountCard(
                    '출석',
                    statusCounts['present']!,
                    provider.getStatusColor('present'),
                    Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatusCountCard(
                    '지각',
                    statusCounts['late']!,
                    provider.getStatusColor('late'),
                    Icons.access_time_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatusCountCard(
                    '결석',
                    statusCounts['absent']!,
                    provider.getStatusColor('absent'),
                    Icons.cancel_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatusCountCard(
                    '공결',
                    statusCounts['excused']!,
                    provider.getStatusColor('excused'),
                    Icons.event_available_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 상태별 카운트 카드
  Widget _buildStatusCountCard(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: AppTypography.headline3(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: AppTypography.small(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 수업별 출석 현황
  Widget _buildClassAttendanceCards(StudentAttendanceProvider provider) {
    final classStats = provider.getClassStatistics();

    if (classStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '수강 중인 과목이 없습니다',
              style: AppTypography.subhead(
                context,
              ).copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
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
                  Icons.school_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '수업별 출석 현황',
                  style: AppTypography.subhead(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classStats.length,
              separatorBuilder:
                  (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final classData = classStats[index];
                return _buildClassCard(provider, classData);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 수업 카드
  Widget _buildClassCard(
    StudentAttendanceProvider provider,
    Map<String, dynamic> classData,
  ) {
    final className = classData['className'] ?? '알 수 없는 수업';
    final attendanceRate = classData['attendanceRate'] ?? 0;
    final totalSessions = classData['totalSessions'] ?? 0;
    final color = provider.getAttendanceRateColor(attendanceRate);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.book_rounded, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: AppTypography.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '총 $totalSessions회 수업',
                  style: AppTypography.small(
                    context,
                  ).copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$attendanceRate%',
              style: AppTypography.small(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 출석 패턴 분석
  Widget _buildAttendancePattern(StudentAttendanceProvider provider) {
    final weeklyPattern = provider.getWeeklyPattern();
    final trend = provider.getRecentTrend();
    final suggestions = provider.getImprovementSuggestions();

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
                  Icons.timeline_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '출석 패턴 분석',
                  style: AppTypography.subhead(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 최근 트렌드
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTrendIcon(trend),
                    color: _getTrendColor(trend),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '최근 트렌드: $trend',
                    style: AppTypography.small(context).copyWith(
                      color: _getTrendColor(trend),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              // 개선 제안
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          color: AppColors.primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '개선 제안',
                          style: AppTypography.small(context).copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...suggestions.map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: AppTypography.small(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 최근 출석 기록
  Widget _buildRecentAttendance(StudentAttendanceProvider provider) {
    final recentAttendance = provider.recentAttendance;

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
                  Icons.history_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '최근 출석 기록',
                  style: AppTypography.subhead(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (recentAttendance.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '최근 출석 기록이 없습니다',
                        style: AppTypography.body(
                          context,
                        ).copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentAttendance.length.clamp(0, 5),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = recentAttendance[index];
                  return _buildAttendanceRecordItem(provider, record);
                },
              ),
          ],
        ),
      ),
    );
  }

  // 출석 기록 아이템
  Widget _buildAttendanceRecordItem(
    StudentAttendanceProvider provider,
    Map<String, dynamic> record,
  ) {
    final className = record['className'] ?? '알 수 없는 수업';
    final date = record['date'] as DateTime;
    final status = record['status'] as String;
    final color = provider.getStatusColor(status);
    final statusText = provider.getStatusText(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(status), color: color, size: 14),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: AppTypography.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${date.month}/${date.day} (${_getWeekdayText(date.weekday)})',
                  style: AppTypography.small(
                    context,
                  ).copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: AppTypography.small(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 학습 목표 달성도
  Widget _buildLearningGoalProgress(StudentAttendanceProvider provider) {
    final goalProgress = provider.getLearningGoalProgress();
    final currentRate = goalProgress['currentRate'] as int;
    final targetRate = goalProgress['targetRate'] as int;
    final isOnTrack = goalProgress['isOnTrack'] as bool;
    final sessionsNeeded = goalProgress['sessionsNeeded'] as int;
    final progressPercentage = goalProgress['progressPercentage'] as int;

    final color = isOnTrack ? AppColors.successColor : AppColors.warningColor;

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
                Icon(Icons.flag_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  '학습 목표 달성도',
                  style: AppTypography.subhead(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 목표 진행률
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '목표 출석률 $targetRate%',
                            style: AppTypography.small(context),
                          ),
                          Text(
                            '$currentRate% / $targetRate%',
                            style: AppTypography.small(
                              context,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressPercentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 목표 달성 메시지
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isOnTrack ? Icons.check_circle : Icons.schedule,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOnTrack
                          ? '목표를 달성했습니다! 계속 유지해주세요.'
                          : '목표 달성까지 $sessionsNeeded회 연속 출석이 필요합니다.',
                      style: AppTypography.small(
                        context,
                      ).copyWith(color: color, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 트렌드 아이콘 반환
  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case '상승':
        return Icons.trending_up_rounded;
      case '하락':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  // 트렌드 색상 반환
  Color _getTrendColor(String trend) {
    switch (trend) {
      case '상승':
        return AppColors.successColor;
      case '하락':
        return AppColors.errorColor;
      default:
        return AppColors.warningColor;
    }
  }

  // 상태 아이콘 반환
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'late':
        return Icons.access_time_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'excused':
        return Icons.event_available_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  // 요일 텍스트 반환
  String _getWeekdayText(int weekday) {
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
}
