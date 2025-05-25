import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';

/// AttenSense 앱에서 사용하는 표준 로딩 인디케이터 위젯
/// 디자인 시스템에 정의된 스타일을 제공합니다.
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final indicatorColor =
        color ?? (isDarkMode ? AppColors.primaryColor : AppColors.primaryColor);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (message != null) ...[
            AppSpacing.verticalSpaceMD,
            Text(
              message!,
              style: AppTypography.small(context),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 화면 전체를 덮는 로딩 인디케이터
/// 백그라운드 작업 중 사용자 상호작용을 방지하기 위해 사용합니다.
class AppFullScreenLoading extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const AppFullScreenLoading({super.key, this.message, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 배경색 추출
    final baseColor =
        isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
    final int argb = baseColor.toARGB32();
    final bgColor =
        backgroundColor ??
        Color.fromRGBO(
          (argb >> 16) & 0xFF, // R 값
          (argb >> 8) & 0xFF, // G 값
          argb & 0xFF, // B 값
          0.7,
        );

    return Container(
      color: bgColor,
      child: AppLoadingIndicator(message: message),
    );
  }
}

/// 버튼 내부에 사용되는 작은 로딩 인디케이터
class AppSmallLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const AppSmallLoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final Color? backgroundColor;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 배경색 추출
    final baseColor =
        isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
    final int argb = baseColor.toARGB32();
    final bgColor =
        backgroundColor ??
        Color.fromRGBO(
          (argb >> 16) & 0xFF, // R 값
          (argb >> 8) & 0xFF, // G 값
          argb & 0xFF, // B 값
          0.7,
        );

    // 오버레이 완성
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: bgColor,
            child: AppLoadingIndicator(message: loadingText),
          ),
      ],
    );
  }
}
