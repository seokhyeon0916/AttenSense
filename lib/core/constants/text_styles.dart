import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capston_design/core/constants/colors.dart';

class AppTextStyles {
  static TextStyle _getTextStyle(
    double fontSize,
    FontWeight fontWeight,
    Color color, {
    double height = 1.0,
  }) {
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }

  // 헤드라인 스타일
  static TextStyle headline1({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      24,
      FontWeight.bold,
      color ??
          (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      height: 1.2,
    );
  }

  static TextStyle headline2({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      20,
      FontWeight.bold,
      color ??
          (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      height: 1.2,
    );
  }

  static TextStyle headline3({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      18,
      FontWeight.w600,
      color ??
          (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      height: 1.3,
    );
  }

  // 서브 헤드 스타일
  static TextStyle subhead({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      16,
      FontWeight.w600,
      color ??
          (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      height: 1.3,
    );
  }

  // 본문 텍스트 스타일
  static TextStyle bodyText({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      14,
      FontWeight.normal,
      color ??
          (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      height: 1.5,
    );
  }

  // 작은 텍스트 스타일
  static TextStyle smallText({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      12,
      FontWeight.normal,
      color ??
          (isDarkMode
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary),
      height: 1.5,
    );
  }

  // 버튼 텍스트 스타일
  static TextStyle buttonText({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      14,
      FontWeight.w500,
      color ??
          (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      height: 1.2,
    );
  }

  // 라벨 텍스트 스타일
  static TextStyle label({Color? color, bool isDarkMode = false}) {
    return _getTextStyle(
      12,
      FontWeight.w500,
      color ??
          (isDarkMode
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary),
      height: 1.2,
    );
  }
}
