import 'package:flutter/material.dart';

/// 반응형 레이아웃을 위한 유틸리티 클래스
class ScreenUtils {
  /// 현재 화면 너비가 모바일 크기인지 확인 (600dp 미만)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// 현재 화면 너비가 태블릿 크기인지 확인 (600dp 이상, 1200dp 미만)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// 현재 화면 너비가 데스크탑 크기인지 확인 (1200dp 이상)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// 현재 화면의 방향이 가로 모드인지 확인
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 현재 화면의 방향이 세로 모드인지 확인
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// 반응형 패딩 값 계산
  ///
  /// [context] 현재 컨텍스트
  /// [defaultValue] 기본 패딩 값
  /// [tabletMultiplier] 태블릿에서의 배수 (기본 1.5)
  /// [desktopMultiplier] 데스크탑에서의 배수 (기본 2.0)
  static double responsivePadding(
    BuildContext context, {
    required double defaultValue,
    double tabletMultiplier = 1.5,
    double desktopMultiplier = 2.0,
  }) {
    if (isDesktop(context)) {
      return defaultValue * desktopMultiplier;
    } else if (isTablet(context)) {
      return defaultValue * tabletMultiplier;
    }
    return defaultValue;
  }

  /// 화면 너비에 따른 반응형 폰트 크기 계산
  ///
  /// [context] 현재 컨텍스트
  /// [defaultSize] 기본 폰트 크기
  /// [minSize] 최소 폰트 크기
  /// [maxSize] 최대 폰트 크기
  static double responsiveFontSize(
    BuildContext context, {
    required double defaultSize,
    double? minSize,
    double? maxSize,
  }) {
    final width = MediaQuery.of(context).size.width;
    final calculatedSize = defaultSize * (width / 400) * 0.8;

    if (minSize != null && calculatedSize < minSize) {
      return minSize;
    }

    if (maxSize != null && calculatedSize > maxSize) {
      return maxSize;
    }

    return calculatedSize;
  }

  /// 화면 너비 기반으로 컨테이너 너비 계산
  ///
  /// [context] 현재 컨텍스트
  /// [percentOfScreen] 화면 대비 퍼센트 (0.0 ~ 1.0)
  /// [maxWidth] 최대 너비
  static double containerWidth(
    BuildContext context, {
    required double percentOfScreen,
    double? maxWidth,
  }) {
    final width = MediaQuery.of(context).size.width * percentOfScreen;

    if (maxWidth != null && width > maxWidth) {
      return maxWidth;
    }

    return width;
  }

  /// 화면 크기에 따른 그리드 열 개수 계산
  ///
  /// [context] 현재 컨텍스트
  /// [mobileColumns] 모바일에서의 열 개수 (기본 1)
  /// [tabletColumns] 태블릿에서의 열 개수 (기본 2)
  /// [desktopColumns] 데스크탑에서의 열 개수 (기본 4)
  static int gridColumns(
    BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 4,
  }) {
    if (isDesktop(context)) {
      return desktopColumns;
    } else if (isTablet(context)) {
      return tabletColumns;
    }
    return mobileColumns;
  }

  /// 화면 크기에 따른 아이템 높이 계산
  ///
  /// [context] 현재 컨텍스트
  /// [defaultHeight] 기본 높이
  /// [scaleFactor] 화면 높이에 따른 스케일 팩터
  static double itemHeight(
    BuildContext context, {
    required double defaultHeight,
    double scaleFactor = 0.0015,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    return defaultHeight + (screenHeight * scaleFactor);
  }

  /// 화면 크기에 따라 다른 위젯 반환
  ///
  /// [context] 현재 컨텍스트
  /// [mobile] 모바일용 위젯
  /// [tablet] 태블릿용 위젯 (제공되지 않으면 mobile 사용)
  /// [desktop] 데스크탑용 위젯 (제공되지 않으면 tablet 또는 mobile 사용)
  static Widget responsiveWidget({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}
