import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';

/// 출석 상태별 파이 차트 위젯
class AttendancePieChart extends StatelessWidget {
  final int present;
  final int late;
  final int absent;
  final bool isDoughnut;
  final double radius;
  final String description;

  const AttendancePieChart({
    super.key,
    required this.present,
    required this.late,
    required this.absent,
    this.isDoughnut = false,
    this.radius = 100,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // 데이터가 없는 경우
    final total = present + late + absent;
    if (total == 0) {
      return Column(
        children: [
          SizedBox(
            height: radius * 2,
            width: radius * 2,
            child: const Center(child: Text('데이터가 없습니다')),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: radius * 2,
          width: radius * 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: isDoughnut ? radius * 0.6 : 0,
              sections: [
                PieChartSectionData(
                  color: AppColors.successColor,
                  value: present.toDouble(),
                  title: '${((present / total) * 100).toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: AppColors.warningColor,
                  value: late.toDouble(),
                  title: '${((late / total) * 100).toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: AppColors.errorColor,
                  value: absent.toDouble(),
                  title: '${((absent / total) * 100).toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(AppColors.successColor, '출석', '$present명'),
            const SizedBox(width: 16),
            _buildLegendItem(AppColors.warningColor, '지각', '$late명'),
            const SizedBox(width: 16),
            _buildLegendItem(AppColors.errorColor, '결석', '$absent명'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label: $value', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
