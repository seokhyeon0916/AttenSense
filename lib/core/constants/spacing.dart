import 'package:flutter/material.dart';

/// AttenSense 앱의 간격 시스템
/// 디자인 문서에 정의된 간격 체계를 제공합니다.
class AppSpacing {
  // 기본 간격 단위 (8px 기반)
  static const double unit = 8.0;

  /// 4px - 매우 작은 요소 사이 간격 (xs)
  static const double xs = unit * 0.5;

  /// 8px - 관련 요소 그룹 내 간격 (s)
  static const double sm = unit;

  /// 16px - 컴포넌트 간 기본 간격 (m)
  static const double md = unit * 2;

  /// 24px - 주요 섹션 간 간격 (l)
  static const double lg = unit * 3;

  /// 32px - 화면 레이아웃 분리를 위한 큰 간격 (xl)
  static const double xl = unit * 4;

  /// 48px - 매우 큰 섹션 간격 (xxl)
  static const double xxl = unit * 6;

  /// 화면 패딩 - 좌우 여백
  static const double screenHorizontalPadding = md;

  /// 화면 패딩 - 상하 여백
  static const double screenVerticalPadding = md;

  /// 카드 내부 패딩
  static const double cardPadding = md;

  /// 목록 항목 간 간격
  static const double listItemSpacing = sm;

  /// 버튼 내부 패딩
  static const double buttonPadding = sm;

  /// 폼 필드 간 간격
  static const double formFieldSpacing = md;

  /// 아이콘 버튼 크기
  static const double iconButtonSize = 48.0;

  /// 터치 가능한 최소 영역 크기 (접근성 기준)
  static const double minTouchSize = 48.0;

  // 화면 여백
  static const screenMargin = EdgeInsets.all(md);
  static const screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // 카드 패딩
  static const cardMargin = EdgeInsets.only(bottom: md);

  // 버튼 패딩
  static const iconButtonPadding = EdgeInsets.all(xs);

  // 버튼 패딩
  static const EdgeInsets buttonPadding2 = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // 폼 요소 간격
  static const formSectionSpacing = SizedBox(height: xl);

  // 리스트 아이템 패딩
  static const listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // 간격 유틸리티
  static SizedBox get verticalSpaceXS => const SizedBox(height: xs);
  static SizedBox get verticalSpaceSM => const SizedBox(height: sm);
  static SizedBox get verticalSpaceMD => const SizedBox(height: md);
  static SizedBox get verticalSpaceLG => const SizedBox(height: lg);
  static SizedBox get verticalSpaceXL => const SizedBox(height: xl);

  static SizedBox get horizontalSpaceXS => const SizedBox(width: xs);
  static SizedBox get horizontalSpaceSM => const SizedBox(width: sm);
  static SizedBox get horizontalSpaceMD => const SizedBox(width: md);
  static SizedBox get horizontalSpaceLG => const SizedBox(width: lg);
  static SizedBox get horizontalSpaceXL => const SizedBox(width: xl);

  // 동적 간격 생성
  static SizedBox verticalSpace(double height) => SizedBox(height: height);
  static SizedBox horizontalSpace(double width) => SizedBox(width: width);
}
