import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'chart_utils.dart';

/// 출석률 추이를 라인 차트로 표시하는 위젯
class AttendanceLineChart extends StatelessWidget {
  /// 주차별 출석 데이터 목록
  final List<Map<String, dynamic>> weeklyData;

  /// 차트 제목
  final String? title;

  /// 차트 설명
  final String description;

  /// 차트 높이
  final double height;

  /// 그래프 라인 색상
  final Color lineColor;

  /// 그래프 배경 색상
  final Color backgroundColor;

  const AttendanceLineChart({
    super.key,
    required this.weeklyData,
    this.title,
    required this.description,
    this.height = 250,
    this.lineColor = const Color(0xFF3B82F6), // AppColors.primaryColor
    this.backgroundColor = const Color(
      0x1A3B82F6,
    ), // AppColors.primaryColor with 10% opacity
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('데이터가 없습니다')),
      );
    }

    // x축 값과 y축 값 추출
    final List<FlSpot> spots = [];
    for (int i = 0; i < weeklyData.length; i++) {
      final data = weeklyData[i];

      // 안전하게 week 값 추출
      final week =
          (data['week'] is int)
              ? (data['week'] as int)
              : (data['week'] is String && (data['week'] as String).isNotEmpty)
              ? int.tryParse(data['week'] as String) ?? (i + 1)
              : (i + 1);

      // 안전하게 rate 값 추출
      final rate =
          (data['rate'] is num)
              ? (data['rate'] as num).toDouble()
              : (data['rate'] is String && (data['rate'] as String).isNotEmpty)
              ? double.tryParse(data['rate'] as String) ?? 0.0
              : 0.0;

      spots.add(FlSpot(week.toDouble(), rate));
    }

    // 최대 주차 계산
    final maxWeek =
        spots.isEmpty
            ? 15.0
            : spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(title!, style: Theme.of(context).textTheme.titleLarge),
          ),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 20,
                verticalInterval: 1,
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) return const SizedBox.shrink();
                      return Text(
                        '${value.toInt()}주',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              minX: 1,
              maxX: maxWeek,
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: backgroundColor),
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
      ],
    );
  }
}
