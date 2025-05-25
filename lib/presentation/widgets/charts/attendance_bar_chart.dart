import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'chart_utils.dart';

/// 출석 현황을 막대 차트로 표시하는 위젯
class AttendanceBarChart extends StatelessWidget {
  /// 차트에 표시할 데이터 목록
  final List<Map<String, dynamic>> data;

  /// X축 라벨을 위한 필드명
  final String xAxisField;

  /// Y축 값을 위한 필드명
  final String yAxisField;

  /// 막대 색상을 결정하는 상태 필드명 (선택사항)
  final String? statusField;

  /// 차트 제목
  final String? title;

  /// 차트 설명
  final String? description;

  /// 차트 높이
  final double height;

  /// 기본 막대 색상
  final Color barColor;

  const AttendanceBarChart({
    super.key,
    required this.data,
    required this.xAxisField,
    required this.yAxisField,
    this.statusField,
    this.title,
    this.description,
    this.height = 250,
    this.barColor = const Color(0xFF3B82F6), // AppColors.primaryColor
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('데이터가 없습니다')),
      );
    }

    // 최대 막대 값 계산
    double maxY = 0;
    for (final item in data) {
      final value = _getValueFromItem(item, yAxisField);
      if (value > maxY) maxY = value;
    }

    // 상한값 올림 처리 (보기 좋게)
    maxY = ((maxY ~/ 10) + 1) * 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(title!, style: Theme.of(context).textTheme.titleLarge),
          ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = data[groupIndex];
                    final xLabel = _getLabelFromItem(item, xAxisField);
                    final value = _getValueFromItem(item, yAxisField);
                    return BarTooltipItem(
                      '$xLabel: ${value.toStringAsFixed(1)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < data.length) {
                        final item = data[value.toInt()];
                        final label = _getLabelFromItem(item, xAxisField);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(value.toInt().toString()),
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                drawVerticalLine: false,
              ),
              barGroups:
                  data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final value = _getValueFromItem(item, yAxisField);

                    Color rodColor = barColor;
                    if (statusField != null && item.containsKey(statusField)) {
                      final status = item[statusField] as String;
                      rodColor = ChartUtils.getStatusColor(status, context);
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: rodColor,
                          width: 15,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// 데이터 아이템에서 X축 라벨 가져오기
  String _getLabelFromItem(Map<String, dynamic> item, String field) {
    if (item.containsKey(field)) {
      final value = item[field];
      return value?.toString() ?? '';
    }
    return '';
  }

  /// 데이터 아이템에서 Y축 값 가져오기
  double _getValueFromItem(Map<String, dynamic> item, String field) {
    if (item.containsKey(field)) {
      final value = item[field];
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        // 백분율 문자열 처리 ('95%' -> 95.0)
        try {
          // 백분율 문자열 처리
          if (value.contains('%')) {
            // %를 제거하고 double로 변환
            return double.tryParse(value.replaceAll('%', '').trim()) ?? 0.0;
          }
          // 일반 숫자 문자열 처리
          return double.tryParse(value) ?? 0.0;
        } catch (e) {
          return 0.0;
        }
      }
    }
    return 0.0;
  }
}
