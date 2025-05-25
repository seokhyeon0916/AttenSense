import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';

/// 앱 전체에서 일관된 카드 스타일을 제공하는 위젯
/// 디자인 시스템에 정의된 스타일과 간격을 사용합니다.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? backgroundColor;
  final Color? shadowColor;
  final BorderRadius? borderRadius;
  final GestureTapCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.shadowColor,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDarkMode
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight);

    final shadowWithOpacity = Color.fromRGBO(
      0, // black red
      0, // black green
      0, // black blue
      isDarkMode ? 0.4 : 0.1,
    );

    final shadow = shadowColor ?? shadowWithOpacity;
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.md);
    const defaultPadding = EdgeInsets.all(AppSpacing.md);

    final card = Container(
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        boxShadow:
            elevation == 0
                ? []
                : [
                  BoxShadow(
                    color: shadow,
                    blurRadius: elevation ?? 4,
                    spreadRadius: (elevation ?? 4) / 4,
                    offset: Offset(0, (elevation ?? 4) / 4),
                  ),
                ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(onTap: onTap, borderRadius: radius, child: card),
      );
    }

    return Padding(padding: margin ?? EdgeInsets.zero, child: card);
  }
}

/// 헤더와 콘텐츠가 있는 카드
/// 헤더와 콘텐츠 사이에 명확한 구분선을 제공합니다.
class AppHeaderCard extends StatelessWidget {
  final Widget header;
  final Widget content;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showDivider;
  final GestureTapCallback? onTap;

  const AppHeaderCard({
    super.key,
    required this.header,
    required this.content,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const defaultPadding = EdgeInsets.all(AppSpacing.md);

    return AppCard(
      padding: EdgeInsets.zero,
      margin: margin,
      elevation: elevation,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: padding ?? defaultPadding, child: header),
          if (showDivider) const Divider(height: 1, thickness: 1),
          Padding(padding: padding ?? defaultPadding, child: content),
        ],
      ),
    );
  }
}
