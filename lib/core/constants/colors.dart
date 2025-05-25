import 'package:flutter/material.dart';

/// AttenSense 앱의 색상 시스템
/// 디자인 문서에 정의된 색상 팔레트를 제공합니다.
class AppColors {
  // 브랜드 색상
  static const Color primaryColor = Color(0xFF3B82F6); // 브랜드 프라이머리 (밝은 블루)
  static const Color secondaryColor = Color(0xFF10B981); // 브랜드 세컨더리 (그린)
  static const Color accentColor = Color(0xFFF59E0B); // 브랜드 액센트 (옐로우)

  // 상태 색상
  static const Color successColor = Color(0xFF10B981); // 성공, 출석 (그린)
  static const Color warningColor = Color(0xFFF59E0B); // 경고, 지각 (옐로우)
  static const Color errorColor = Color(0xFFEF4444); // 오류, 결석 (레드)
  static const Color neutralColor = Color(0xFF64748B); // 중립, 비활성 (슬레이트)

  // 배경 색상 - 라이트 모드
  static const Color backgroundLight = Color(0xFFFFFFFF); // 기본 배경 (화이트)
  static const Color backgroundSecondaryLight = Color(
    0xFFF1F5F9,
  ); // 보조 배경 (라이트 그레이)
  static const Color cardBackgroundLight = Color(0xFFFFFFFF); // 카드 배경 (화이트)
  static const Color backgroundElevatedLight = Color(0xFFFFFFFF); // 카드 배경 (화이트)

  // 배경 색상 - 다크 모드
  static const Color backgroundDark = Color(0xFF1E293B); // 기본 배경 (다크 블루)
  static const Color backgroundSecondaryDark = Color(
    0xFF0F172A,
  ); // 보조 배경 (디퍼 다크 블루)
  static const Color cardBackgroundDark = Color(
    0xFF334155,
  ); // 카드 배경 (미디엄 다크 블루)
  static const Color backgroundElevatedDark = Color(
    0xFF334155,
  ); // 카드 배경 (미디엄 다크 블루)

  // 텍스트 색상 - 라이트 모드
  static const Color lightTextPrimary = Color(0xFF0F172A); // 주요 텍스트 (다크 블루)
  static const Color lightTextSecondary = Color(0xFF64748B); // 보조 텍스트 (슬레이트)

  // 텍스트 색상 - 다크 모드
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // 주요 텍스트 (오프 화이트)
  static const Color darkTextSecondary = Color(0xFF94A3B8); // 보조 텍스트 (라이트 슬레이트)

  // 텍스트 색상 (공통)
  static const Color textSecondary = Color(0xFF64748B); // 보조 텍스트 (슬레이트)

  // 그라데이션
  static const List<Color> primaryGradient = [primaryColor, Color(0xFF2563EB)];
  static const List<Color> successGradient = [
    secondaryColor,
    Color(0xFF059669),
  ];

  // 불투명도가 있는 색상
  static Color primaryWithOpacity(double opacity) => Color.fromRGBO(
    primaryColor.r.toInt(),
    primaryColor.g.toInt(),
    primaryColor.b.toInt(),
    opacity,
  );

  static Color secondaryWithOpacity(double opacity) => Color.fromRGBO(
    secondaryColor.r.toInt(),
    secondaryColor.g.toInt(),
    secondaryColor.b.toInt(),
    opacity,
  );

  static Color errorWithOpacity(double opacity) => Color.fromRGBO(
    errorColor.r.toInt(),
    errorColor.g.toInt(),
    errorColor.b.toInt(),
    opacity,
  );

  // 추가 UI 요소 색상
  static const Color dividerLight = Color(0xFFE2E8F0); // 라이트 모드 구분선
  static const Color dividerDark = Color(0xFF2D3748); // 다크 모드 구분선
  static const Color inputBorderLight = Color(0xFFCBD5E1); // 라이트 모드 입력 테두리
  static const Color inputBorderDark = Color(0xFF475569); // 다크 모드 입력 테두리
}
