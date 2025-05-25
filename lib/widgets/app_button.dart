import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';

/// 버튼 타입 정의
enum ButtonType { primary, secondary, text, success, warning, error }

/// AttenSense 앱에서 사용하는 표준 버튼 위젯
/// 디자인 시스템에 정의된 버튼 스타일을 제공합니다.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;
  final double? height;
  final double iconSize;
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.height = 48.0,
    this.iconSize = 20.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: _buildButtonByType(context),
    );
  }

  Widget _buildButtonByType(BuildContext context) {
    final radius = borderRadius ?? 8.0;
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    );

    // 버튼이 비활성화되어야 하는지 확인
    final bool isDisabled = isLoading || onPressed == null;

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primaryWithOpacity(0.6),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _buildButtonContent(context, Colors.white),
        );

      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: BorderSide(
              color:
                  isDisabled
                      ? AppColors.primaryWithOpacity(0.5)
                      : AppColors.primaryColor,
            ),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _buildButtonContent(context, AppColors.primaryColor),
        );

      case ButtonType.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _buildButtonContent(context, AppColors.primaryColor),
        );

      case ButtonType.success:
        // AppColors.successColor 값을 RGB 컴포넌트로 분리
        const successColor = AppColors.successColor;
        final int argb = successColor.toARGB32();
        final successColorWithOpacity = Color.fromRGBO(
          (argb >> 16) & 0xFF, // R 값 추출
          (argb >> 8) & 0xFF, // G 값 추출
          argb & 0xFF, // B 값 추출
          0.6,
        );

        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: successColorWithOpacity,
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _buildButtonContent(context, Colors.white),
        );

      case ButtonType.warning:
        // AppColors.warningColor 값을 RGB 컴포넌트로 분리
        const warningColor = AppColors.warningColor;
        final int argb = warningColor.toARGB32();
        final warningColorWithOpacity = Color.fromRGBO(
          (argb >> 16) & 0xFF, // R 값 추출
          (argb >> 8) & 0xFF, // G 값 추출
          argb & 0xFF, // B 값 추출
          0.6,
        );

        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warningColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: warningColorWithOpacity,
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _buildButtonContent(context, Colors.white),
        );

      case ButtonType.error:
        // AppColors.errorColor 값을 RGB 컴포넌트로 분리
        const errorColor = AppColors.errorColor;
        final int argb = errorColor.toARGB32();
        final errorColorWithOpacity = Color.fromRGBO(
          (argb >> 16) & 0xFF, // R 값 추출
          (argb >> 8) & 0xFF, // G 값 추출
          argb & 0xFF, // B 값 추출
          0.6,
        );

        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: errorColorWithOpacity,
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _buildButtonContent(context, Colors.white),
        );
    }
  }

  Widget _buildButtonContent(BuildContext context, Color color) {
    final textStyle = AppTypography.button(context).copyWith(color: color);

    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color),
          AppSpacing.horizontalSpaceSM,
          Flexible(
            child: Text(
              text,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: textStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
