import 'package:flutter/material.dart';
import 'colors.dart';

/// 앱 전반에서 사용하는 타이포그래피 스타일을 정의합니다.
class AppTypography {
  // 헤드라인 1: 24px, Bold, 1.2 라인 높이
  static TextStyle headline1(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;

    return TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      height: 1.2,
      color: color,
    );
  }

  // 헤드라인 2: 20px, Bold, 1.2 라인 높이
  static TextStyle headline2(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;

    return TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      height: 1.2,
      color: color,
    );
  }

  // 헤드라인 3: 18px, SemiBold, 1.3 라인 높이
  static TextStyle headline3(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;

    return TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600, // SemiBold
      height: 1.3,
      color: color,
    );
  }

  // 서브헤드: 16px, SemiBold, 1.3 라인 높이
  static TextStyle subhead(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;

    return TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600, // SemiBold
      height: 1.3,
      color: color,
    );
  }

  // 본문 텍스트: 14px, Regular, 1.5 라인 높이
  static TextStyle body(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;

    return TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: color,
    );
  }

  // 본문 텍스트 - 강조: 14px, Medium, 1.5 라인 높이
  static TextStyle bodyEmphasis(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;

    return TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500, // Medium
      height: 1.5,
      color: color,
    );
  }

  // 작은 텍스트: 12px, Regular, 1.5 라인 높이
  static TextStyle small(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextSecondary
            : AppColors.darkTextSecondary;

    return TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: color,
    );
  }

  // 버튼 텍스트: 14px, Medium, 1.2 라인 높이
  static TextStyle button(BuildContext context) {
    return const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500, // Medium
      height: 1.2,
      letterSpacing: 0.5,
    );
  }

  // 라벨: 12px, Medium, 1.2 라인 높이
  static TextStyle label(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextSecondary
            : AppColors.darkTextSecondary;

    return TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w500, // Medium
      height: 1.2,
      letterSpacing: 0.5,
      color: color,
    );
  }

  // 입력 필드: 14px, Regular, 1.5 라인 높이
  static TextStyle input(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;

    return TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: color,
    );
  }

  // 캡션 텍스트: 10px, Regular, 1.2 라인 높이
  static TextStyle caption(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        brightness == Brightness.light
            ? AppColors.lightTextSecondary
            : AppColors.darkTextSecondary;

    return TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.normal,
      height: 1.2,
      color: color,
    );
  }
}
