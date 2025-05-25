import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 일관된 색상을 정의하는 클래스
class AppColors {
  // 기본 색상
  static const Color primaryColor = Color(0xFF3B82F6);    // 밝은 파란색
  static const Color secondaryColor = Color(0xFF10B981);  // 그린
  static const Color accentColor = Color(0xFFF59E0B);     // 옐로우

  // 상태 색상
  static const Color successColor = Color(0xFF10B981);    // 그린
  static const Color warningColor = Color(0xFFF59E0B);    // 옐로우
  static const Color errorColor = Color(0xFFEF4444);      // 레드
  static const Color infoColor = Color(0xFF3B82F6);       // 파란색

  // 배경 색상
  static const Color backgroundPrimaryLight = Color(0xFFFFFFFF);    // 화이트
  static const Color backgroundSecondaryLight = Color(0xFFF1F5F9);  // 라이트 그레이
  static const Color backgroundPrimaryDark = Color(0xFF1E293B);     // 다크 블루
  static const Color backgroundSecondaryDark = Color(0xFF0F172A);   // 디퍼 다크 블루

  // 텍스트 색상
  static const Color lightTextPrimary = Color(0xFF0F172A);       // 다크 블루
  static const Color lightTextSecondary = Color(0xFF64748B);     // 슬레이트
  static const Color darkTextPrimary = Color(0xFFF8FAFC);        // 오프 화이트
  static const Color darkTextSecondary = Color(0xFF94A3B8);      // 라이트 슬레이트

  // 기타 사용 색상
  static const Color dividerColor = Color(0xFFE2E8F0);           // 분할선 색상
  static const Color cardBorderColor = Color(0xFFE2E8F0);        // 카드 테두리 색상
  static const Color shadowColor = Color(0x1A000000);            // 그림자 색상 (10% 투명도)
}