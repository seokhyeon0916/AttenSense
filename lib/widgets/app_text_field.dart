import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';

/// AttenSense 앱에서 사용하는 표준 텍스트 입력 필드 위젯
/// 디자인 시스템에 정의된 입력 필드 스타일을 제공합니다.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isEnabled;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final Function()? onEditingComplete;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? helperText;
  final bool filled;
  final Color? backgroundColor;
  final double borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.isEnabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.helperText,
    this.filled = true,
    this.backgroundColor,
    this.borderRadius = 8,
    this.border,
    this.boxShadow,
    this.labelStyle,
    this.textStyle,
    this.hintStyle,
    this.errorStyle,
    this.helperStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultLabelStyle = AppTypography.label(context);
    final helperTextStyle = AppTypography.small(context);
    final errorTextStyle = AppTypography.small(
      context,
    ).copyWith(color: AppColors.errorColor);
    final fillColor =
        filled
            ? backgroundColor ??
                (isDarkMode
                    ? AppColors.backgroundSecondaryDark
                    : AppColors.backgroundSecondaryLight)
            : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...[
          Text(label, style: labelStyle ?? defaultLabelStyle),
          AppSpacing.verticalSpaceSM,
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
            boxShadow: boxShadow,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: textStyle ?? AppTypography.body(context),
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: maxLines,
            minLines: maxLines,
            readOnly: readOnly,
            enabled: isEnabled,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            autofocus: autofocus,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              errorText: errorText,
              helperText: helperText,
              helperStyle: helperStyle ?? helperTextStyle,
              errorStyle: errorStyle ?? errorTextStyle,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.errorColor),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              hintStyle:
                  hintStyle ??
                  AppTypography.body(context).copyWith(
                    color:
                        isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
