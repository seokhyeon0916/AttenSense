import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 애니메이션 유틸리티
class AnimationUtils {
  /// 표준 애니메이션 지속 시간
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// 빠른 애니메이션 지속 시간
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// 느린 애니메이션 지속 시간
  static const Duration slowDuration = Duration(milliseconds: 500);

  /// 표준 애니메이션 커브
  static const Curve defaultCurve = Curves.easeInOut;

  /// 진입 애니메이션 커브
  static const Curve entryCurve = Curves.easeOut;

  /// 퇴장 애니메이션 커브
  static const Curve exitCurve = Curves.easeIn;

  /// 탄력적인 애니메이션 커브
  static const Curve bouncyCurve = Curves.elasticOut;

  /// 페이드 인 애니메이션을 적용한 위젯 반환
  ///
  /// [child] 애니메이션을 적용할 위젯
  /// [duration] 애니메이션 지속 시간 (기본값: 300ms)
  /// [curve] 애니메이션 커브 (기본값: easeInOut)
  /// [delay] 애니메이션 시작 전 지연 시간
  static Widget fadeIn({
    required Widget child,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  /// 슬라이드 애니메이션을 적용한 위젯 반환
  ///
  /// [child] 애니메이션을 적용할 위젯
  /// [direction] 슬라이드 방향 (기본값: 아래에서 위로)
  /// [offset] 슬라이드 거리 (기본값: 50.0)
  /// [duration] 애니메이션 지속 시간 (기본값: 300ms)
  /// [curve] 애니메이션 커브 (기본값: easeInOut)
  static Widget slideIn({
    required Widget child,
    SlideDirection direction = SlideDirection.fromBottom,
    double offset = 50.0,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    Offset begin;

    switch (direction) {
      case SlideDirection.fromTop:
        begin = Offset(0, -offset);
        break;
      case SlideDirection.fromBottom:
        begin = Offset(0, offset);
        break;
      case SlideDirection.fromLeft:
        begin = Offset(-offset, 0);
        break;
      case SlideDirection.fromRight:
        begin = Offset(offset, 0);
        break;
    }

    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: child,
    );
  }

  /// 페이드와 슬라이드를 함께 적용한 애니메이션 위젯 반환
  ///
  /// [child] 애니메이션을 적용할 위젯
  /// [direction] 슬라이드 방향 (기본값: 아래에서 위로)
  /// [offset] 슬라이드 거리 (기본값: 30.0)
  /// [duration] 애니메이션 지속 시간 (기본값: 300ms)
  /// [curve] 애니메이션 커브 (기본값: easeInOut)
  static Widget fadeSlideIn({
    required Widget child,
    SlideDirection direction = SlideDirection.fromBottom,
    double offset = 30.0,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return fadeIn(
      duration: duration,
      curve: curve,
      child: slideIn(
        direction: direction,
        offset: offset,
        duration: duration,
        curve: curve,
        child: child,
      ),
    );
  }

  /// 스케일 애니메이션을 적용한 위젯 반환
  ///
  /// [child] 애니메이션을 적용할 위젯
  /// [beginScale] 시작 스케일 (기본값: 0.8)
  /// [endScale] 끝 스케일 (기본값: 1.0)
  /// [duration] 애니메이션 지속 시간 (기본값: 300ms)
  /// [curve] 애니메이션 커브 (기본값: easeInOut)
  static Widget scaleIn({
    required Widget child,
    double beginScale = 0.8,
    double endScale = 1.0,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: beginScale, end: endScale),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  /// 로딩 애니메이션 위젯 반환
  ///
  /// [size] 로딩 애니메이션 크기 (기본값: 24.0)
  /// [color] 로딩 애니메이션 색상 (기본값: null, 테마 색상 사용)
  static Widget loadingAnimation({double size = 24.0, Color? color}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size / 8,
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
      ),
    );
  }

  /// 펄스 애니메이션을 적용한 위젯 반환
  ///
  /// [child] 애니메이션을 적용할 위젯
  /// [minScale] 최소 스케일 (기본값: 0.97)
  /// [maxScale] 최대 스케일 (기본값: 1.03)
  /// [duration] 애니메이션 지속 시간 (기본값: 1초)
  static Widget pulseAnimation({
    required Widget child,
    double minScale = 0.97,
    double maxScale = 1.03,
    Duration duration = const Duration(seconds: 1),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      onEnd: () {},
      child: child,
    );
  }

  /// 페이지 전환 애니메이션 (라우트 트랜지션)
  ///
  /// [page] 전환할 페이지 위젯
  /// [type] 전환 애니메이션 유형
  /// [duration] 애니메이션 지속 시간 (기본값: 300ms)
  /// [curve] 애니메이션 커브 (기본값: easeInOut)
  static Route<T> pageTransition<T>({
    required Widget page,
    PageTransitionType type = PageTransitionType.fade,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        switch (type) {
          case PageTransitionType.fade:
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.rightToLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.leftToRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.bottomToTop:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.topToBottom:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.scale:
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.fadeAndScale:
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(curvedAnimation),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
        }
      },
    );
  }
}

/// 슬라이드 방향 열거형
enum SlideDirection { fromTop, fromBottom, fromLeft, fromRight }

/// 페이지 전환 애니메이션 유형 열거형
enum PageTransitionType {
  fade,
  rightToLeft,
  leftToRight,
  bottomToTop,
  topToBottom,
  scale,
  fadeAndScale,
}
