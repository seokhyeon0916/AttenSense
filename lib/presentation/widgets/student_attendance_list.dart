import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../domain/entities/attendance_entity.dart' as entity;
import '../../domain/models/attendance_model.dart' as model;
import '../providers/attendance_provider.dart';
import 'app_loading_indicator.dart';
import 'app_error_widget.dart';
import 'app_divider.dart';

class StudentAttendanceList extends ConsumerWidget {
  final String sessionId;
  final bool isSessionActive;

  const StudentAttendanceList({
    super.key,
    required this.sessionId,
    required this.isSessionActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(sessionAttendanceProvider(sessionId));

    if (attendanceState.isLoading) {
      return const Center(
        child: AppLoadingIndicator(message: '학생 출석 데이터를 불러오는 중...'),
      );
    }

    if (attendanceState.errorMessage != null) {
      return AppErrorWidget(
        message: attendanceState.errorMessage!,
        onRetry:
            () =>
                ref
                    .read(sessionAttendanceProvider(sessionId).notifier)
                    .loadAttendances(),
      );
    }

    if (attendanceState.attendances.isEmpty) {
      return const Center(child: Text('현재 출석 데이터가 없습니다.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${attendanceState.attendances.length}명',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _buildStatusSummary(attendanceState.attendances),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: attendanceState.attendances.length,
            separatorBuilder: (_, __) => const AppDivider(),
            itemBuilder: (context, index) {
              final attendance = attendanceState.attendances[index];
              return _buildStudentItem(
                context,
                attendance,
                isSessionActive,
                ref,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSummary(List<entity.AttendanceEntity> attendances) {
    // 출석 상태 요약 계산
    int present = 0;
    int absent = 0;
    int late = 0;
    int excused = 0;

    for (final attendance in attendances) {
      switch (attendance.status) {
        case entity.AttendanceStatus.present:
          present++;
          break;
        case entity.AttendanceStatus.absent:
          absent++;
          break;
        case entity.AttendanceStatus.late:
          late++;
          break;
        case entity.AttendanceStatus.excused:
          excused++;
          break;
      }
    }

    return Row(
      children: [
        _buildStatusIndicator('출석', present, AppColors.successColor),
        const SizedBox(width: AppSpacing.sm),
        _buildStatusIndicator('지각', late, AppColors.warningColor),
        const SizedBox(width: AppSpacing.sm),
        _buildStatusIndicator('결석', absent, AppColors.errorColor),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label: $count'),
      ],
    );
  }

  Widget _buildStudentItem(
    BuildContext context,
    entity.AttendanceEntity attendance,
    bool isSessionActive,
    WidgetRef ref,
  ) {
    // 출석 상태에 따른 색상 설정
    Color statusColor;
    String statusText;

    switch (attendance.status) {
      case entity.AttendanceStatus.present:
        statusColor = AppColors.successColor;
        statusText = '출석';
        break;
      case entity.AttendanceStatus.late:
        statusColor = AppColors.warningColor;
        statusText = '지각';
        break;
      case entity.AttendanceStatus.absent:
        statusColor = AppColors.errorColor;
        statusText = '결석';
        break;
      case entity.AttendanceStatus.excused:
        statusColor = Colors.blue;
        statusText = '공결';
        break;
    }

    // 마지막 활동 시간 계산
    String activityStatusText = '활동 없음';
    Color activityStatusColor = AppColors.errorColor;

    if (attendance.activityLogs.isNotEmpty) {
      final lastLog = attendance.activityLogs.last;
      final minutesSinceLastActivity =
          DateTime.now().difference(lastLog.timestamp).inMinutes;

      if (lastLog.isActive) {
        activityStatusText = '활동 중';
        activityStatusColor = AppColors.successColor;
      } else if (minutesSinceLastActivity < 5) {
        activityStatusText = '$minutesSinceLastActivity분 전 활동';
        activityStatusColor = AppColors.warningColor;
      } else {
        activityStatusText = '$minutesSinceLastActivity분간 비활동';
        activityStatusColor = AppColors.errorColor;
      }
    }

    return InkWell(
      onTap: () => _showStudentActivityDialog(context, attendance, ref),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            // 학생 기본 정보
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendance.studentId,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${attendance.recordedTime.hour}:${attendance.recordedTime.minute.toString().padLeft(2, '0')} 체크인',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // 출석 상태
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 활동 상태
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.only(left: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: activityStatusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activityStatusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: activityStatusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 액션 버튼 (세션이 활성화된 경우에만)
            if (isSessionActive)
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed:
                    () => _showStatusUpdateDialog(context, attendance, ref),
              ),
          ],
        ),
      ),
    );
  }

  void _updateAttendanceStatus(
    WidgetRef ref,
    String attendanceId,
    model.AttendanceStatus status,
  ) {
    ref
        .read(sessionAttendanceProvider(sessionId).notifier)
        .updateAttendanceStatus(attendanceId, status);
  }

  void _showStatusUpdateDialog(
    BuildContext context,
    entity.AttendanceEntity attendance,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('출석 상태 변경'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('출석'),
                  onTap: () {
                    _updateAttendanceStatus(
                      ref,
                      attendance.id,
                      model.AttendanceStatus.present,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('지각'),
                  onTap: () {
                    _updateAttendanceStatus(
                      ref,
                      attendance.id,
                      model.AttendanceStatus.late,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('결석'),
                  onTap: () {
                    _updateAttendanceStatus(
                      ref,
                      attendance.id,
                      model.AttendanceStatus.absent,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('공결'),
                  onTap: () {
                    _updateAttendanceStatus(
                      ref,
                      attendance.id,
                      model.AttendanceStatus.excused,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showStudentActivityDialog(
    BuildContext context,
    entity.AttendanceEntity attendance,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${attendance.studentId} 활동 기록'),
          content: SizedBox(
            width: double.maxFinite,
            child:
                attendance.activityLogs.isEmpty
                    ? const Center(child: Text('활동 기록이 없습니다.'))
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: attendance.activityLogs.length,
                      itemBuilder: (context, index) {
                        final log = attendance.activityLogs[index];
                        final time =
                            '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}';

                        return ListTile(
                          leading: Icon(
                            log.isActive ? Icons.check_circle : Icons.error,
                            color:
                                log.isActive
                                    ? AppColors.successColor
                                    : AppColors.errorColor,
                          ),
                          title: Text(log.isActive ? '활동 감지' : '비활동 감지'),
                          subtitle: Text('시간: $time'),
                          trailing:
                              log.confidenceScore != null
                                  ? Text(
                                    '정확도: ${(log.confidenceScore! * 100).toStringAsFixed(0)}%',
                                  )
                                  : null,
                        );
                      },
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
