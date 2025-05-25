import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';

/// 앱 전체에서 일관된 디바이더(구분선) 스타일을 제공하는 위젯
/// 디자인 시스템에 정의된 스타일과 간격을 사용합니다.
class AppDivider extends StatelessWidget {
  /// 구분선 높이 (기본값: 1)
  final double height;

  /// 구분선 두께 (기본값: 1)
  final double thickness;

  /// 구분선 색상 (기본값: 테마 기반 자동 설정)
  final Color? color;

  /// 구분선 상하 여백 (기본값: 없음)
  final EdgeInsetsGeometry? margin;

  /// 구분선 좌우 간격 (기본값: 0)
  final double indent;
  final double endIndent;

  /// 구분선에 기본 들여쓰기 적용 여부
  final bool hasIndent;

  const AppDivider({
    super.key,
    this.height = 1,
    this.thickness = 1,
    this.color,
    this.margin,
    this.indent = 0,
    this.endIndent = 0,
    this.hasIndent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 색상 추출 및 투명도 적용
    final baseColor =
        isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final int argb = baseColor.toARGB32();
    final dividerColor =
        color ??
        Color.fromRGBO(
          (argb >> 16) & 0xFF, // R 값
          (argb >> 8) & 0xFF, // G 값
          argb & 0xFF, // B 값
          0.2, // 투명도
        );

    final effectiveIndent = hasIndent ? AppSpacing.md : indent;
    final effectiveEndIndent = hasIndent ? AppSpacing.md : endIndent;

    final divider = Divider(
      height: height,
      thickness: thickness,
      color: dividerColor,
      indent: effectiveIndent,
      endIndent: effectiveEndIndent,
    );

    if (margin != null) {
      return Padding(padding: margin!, child: divider);
    }
    return divider;
  }
}

/// 수직 디바이더 위젯
class AppVerticalDivider extends StatelessWidget {
  /// 구분선 너비 (기본값: 1)
  final double width;

  /// 구분선 두께 (기본값: 1)
  final double thickness;

  /// 구분선 색상 (기본값: 테마 기반 자동 설정)
  final Color? color;

  /// 구분선 좌우 여백 (기본값: 없음)
  final EdgeInsetsGeometry? margin;

  /// 구분선 상하 간격 (기본값: 0)
  final double indent;
  final double endIndent;

  const AppVerticalDivider({
    super.key,
    this.width = 1,
    this.thickness = 1,
    this.color,
    this.margin,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 색상 추출 및 투명도 적용
    final baseColor =
        isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final int argb = baseColor.toARGB32();
    final dividerColor =
        color ??
        Color.fromRGBO(
          (argb >> 16) & 0xFF, // R 값
          (argb >> 8) & 0xFF, // G 값
          argb & 0xFF, // B 값
          0.2, // 투명도
        );

    final divider = VerticalDivider(
      width: width,
      thickness: thickness,
      color: dividerColor,
      indent: indent,
      endIndent: endIndent,
    );

    if (margin != null) {
      return Padding(padding: margin!, child: divider);
    }
    return divider;
  }
}

/// 섹션 구분용 더 큰 마진을 가진 디바이더
class AppSectionDivider extends StatelessWidget {
  final Color? color;
  final double thickness;

  const AppSectionDivider({super.key, this.color, this.thickness = 1.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSpacing.verticalSpaceMD,
        AppDivider(color: color, thickness: thickness, hasIndent: true),
        AppSpacing.verticalSpaceMD,
      ],
    );
  }
}
