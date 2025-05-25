import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:intl/intl.dart';

/// 주차별 출석 타임라인 차트 위젯
class AttendanceTimelineChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final Function(Map<String, dynamic>) onItemTap;

  const AttendanceTimelineChart({
    super.key,
    required this.weeklyData,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeklyData.length,
      itemBuilder: (context, index) {
        final weekData = weeklyData[index];
        final week = weekData['week'] as int? ?? (index + 1);
        final status = weekData['status'] as String? ?? 'absent';
        final date = weekData['date'] as DateTime? ?? DateTime.now();
        final description = weekData['description'] as String? ?? '수업 정보 없음';

        final dateFormat = DateFormat('yyyy년 MM월 dd일');
        final formattedDate = dateFormat.format(date);

        Color statusColor;
        IconData statusIcon;
        String statusText;

        switch (status) {
          case 'present':
            statusColor = AppColors.successColor;
            statusIcon = Icons.check_circle;
            statusText = '출석';
            break;
          case 'late':
            statusColor = AppColors.warningColor;
            statusIcon = Icons.watch_later;
            statusText = '지각';
            break;
          case 'absent':
            statusColor = AppColors.errorColor;
            statusIcon = Icons.cancel;
            statusText = '결석';
            break;
          case 'future':
            statusColor = Colors.grey;
            statusIcon = Icons.calendar_today;
            statusText = '예정';
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help_outline;
            statusText = '미정';
        }

        // 타임라인 아이템 위젯
        return InkWell(
          onTap: () => onItemTap(weekData),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 타임라인 라인
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 14),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      width: 2,
                      height: 60,
                      color:
                          index < weeklyData.length - 1
                              ? Colors.grey.shade300
                              : Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // 오른쪽 콘텐츠
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$week주차',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
