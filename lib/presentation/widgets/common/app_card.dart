import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/core/utils/animation_utils.dart';

/// 앱에서 사용하는 기본 카드 컴포넌트
///
/// 카드 컨테이너에 일관된 스타일과 애니메이션을 적용합니다.
class AppCard extends StatelessWidget {
  /// 카드 내용 위젯
  final Widget child;

  /// 카드 제목 (선택사항)
  final String? title;

  /// 카드 부제목 (선택사항)
  final String? subtitle;

  /// 카드 헤더 오른쪽 위젯 (선택사항)
  final Widget? trailing;

  /// 카드 아이콘 (선택사항)
  final IconData? icon;

  /// 카드 클릭 콜백 (선택사항)
  final VoidCallback? onTap;

  /// 패딩 (기본값: 카드 패딩)
  final EdgeInsetsGeometry padding;

  /// 마진 (기본값: 기본 간격)
  final EdgeInsetsGeometry margin;

  /// 카드 배경색
  final Color? backgroundColor;

  /// 테두리 색상 (선택사항)
  final Color? borderColor;

  /// 테두리 두께 (기본값: 0)
  final double borderWidth;

  /// 그림자 강도 (기본값: 1)
  final double elevation;

  /// 모서리 반경 (기본값: 카드 모서리 반경)
  final double borderRadius;

  /// 콘텐츠 사이 간격 (기본값: 기본 간격)
  final double contentSpacing;

  /// 애니메이션 적용 여부 (기본값: true)
  final bool animated;

  /// 헤더 표시 여부 (기본값: title 또는 subtitle이 있으면 표시)
  final bool showHeader;

  /// 클릭 효과 표시 여부 (기본값: onTap이 있으면 표시)
  final bool showTapEffect;

  /// 카드 컴포넌트 생성자
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = const EdgeInsets.all(AppSpacing.md),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.elevation = 1,
    this.borderRadius = 12.0,
    this.contentSpacing = AppSpacing.md,
    this.animated = true,
    this.showHeader = true,
    this.showTapEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color cardColor =
        backgroundColor ??
        (isDarkMode
            ? AppColors.backgroundElevatedDark
            : AppColors.backgroundElevatedLight);

    final bool hasHeader =
        showHeader && (title != null || subtitle != null || icon != null);

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          _buildHeader(context),
          SizedBox(height: contentSpacing),
        ],
        child,
      ],
    );

    // 카드 기본 스타일
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border:
            borderColor != null || borderWidth > 0
                ? Border.all(
                  color: borderColor ?? theme.dividerColor.withOpacity(0.1),
                  width: borderWidth,
                )
                : null,
        boxShadow:
            elevation > 0
                ? [
                  BoxShadow(
                    color: (isDarkMode ? Colors.black : Colors.black54)
                        .withOpacity(0.05 * elevation),
                    offset: Offset(0, 1 * elevation),
                    blurRadius: 3 * elevation,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: cardContent,
    );

    // 클릭 효과가 있는 경우
    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor:
            showTapEffect
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
        highlightColor:
            showTapEffect
                ? theme.primaryColor.withOpacity(0.05)
                : Colors.transparent,
        child: card,
      );
    }

    // 마진 적용
    card = Padding(padding: margin, child: card);

    // 애니메이션 적용
    if (animated) {
      card = AnimationUtils.fadeSlideIn(
        child: card,
        direction: SlideDirection.fromBottom,
        offset: 10,
        duration: const Duration(milliseconds: 200),
      );
    }

    return card;
  }

  /// 카드 헤더 위젯 생성
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: AppTypography.subhead(context),
                  overflow: TextOverflow.ellipsis,
                ),
              if (title != null && subtitle != null) const SizedBox(height: 2),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.small(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 배지가 있는 카드 컴포넌트
///
/// AppCard의 확장 버전으로 카드 오른쪽 상단에 배지를 표시할 수 있습니다.
class BadgedCard extends StatelessWidget {
  /// 카드 내용 위젯
  final Widget child;

  /// 카드 제목 (선택사항)
  final String? title;

  /// 카드 부제목 (선택사항)
  final String? subtitle;

  /// 카드 아이콘 (선택사항)
  final IconData? icon;

  /// 카드 클릭 콜백 (선택사항)
  final VoidCallback? onTap;

  /// 배지 텍스트
  final String badgeText;

  /// 배지 색상 (기본값: 주 색상)
  final Color? badgeColor;

  /// 배지 텍스트 색상 (기본값: 흰색)
  final Color? badgeTextColor;

  /// 기타 카드 속성
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final double? borderRadius;

  /// 배지가 있는 카드 생성자
  const BadgedCard({
    super.key,
    required this.child,
    required this.badgeText,
    this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.badgeColor,
    this.badgeTextColor,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppCard(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onTap: onTap,
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          margin: margin ?? const EdgeInsets.all(AppSpacing.md),
          backgroundColor: backgroundColor,
          elevation: elevation ?? 1,
          borderRadius: borderRadius ?? 12.0,
          child: child,
        ),
        Positioned(
          top: (margin?.vertical ?? AppSpacing.md) - 6,
          right: (margin?.horizontal ?? AppSpacing.md) - 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor ?? Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              badgeText,
              style: AppTypography.caption(context).copyWith(
                color: badgeTextColor ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 그라데이션 배경이 있는 카드 컴포넌트
///
/// AppCard의 확장 버전으로 그라데이션 배경을 적용할 수 있습니다.
class GradientCard extends StatelessWidget {
  /// 카드 내용 위젯
  final Widget child;

  /// 그라데이션 색상 목록
  final List<Color> colors;

  /// 그라데이션 시작 위치
  final Alignment begin;

  /// 그라데이션 끝 위치
  final Alignment end;

  /// 카드 제목 (선택사항)
  final String? title;

  /// 카드 부제목 (선택사항)
  final String? subtitle;

  /// 카드 아이콘 (선택사항)
  final IconData? icon;

  /// 카드 클릭 콜백 (선택사항)
  final VoidCallback? onTap;

  /// 기타 카드 속성
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double? borderRadius;

  /// 그라데이션 배경이 있는 카드 생성자
  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
  }) : assert(colors.length >= 2, '그라데이션을 위해 최소 2개의 색상이 필요합니다.');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: margin ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: begin, end: end),
            borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
            boxShadow:
                elevation != null && elevation! > 0
                    ? [
                      BoxShadow(
                        color: colors.last.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Padding(
                padding:
                    padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null || subtitle != null || icon != null) ...[
                      _buildHeader(context),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 카드 헤더 위젯 생성
  Widget _buildHeader(BuildContext context) {
    final bool isDarkGradient = _isGradientDark();
    final Color textColor = isDarkGradient ? Colors.white : Colors.black87;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: AppTypography.subhead(
                    context,
                  ).copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              if (title != null && subtitle != null) const SizedBox(height: 2),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.small(
                    context,
                  ).copyWith(color: textColor.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 그라데이션이 어두운지 확인 (텍스트 색상 결정용)
  bool _isGradientDark() {
    // 첫 번째와 마지막 색상의 휘도를 계산
    final double luminance1 = colors.first.computeLuminance();
    final double luminance2 = colors.last.computeLuminance();

    // 평균 휘도가 0.5보다 작으면 어두운 것으로 판단
    return (luminance1 + luminance2) / 2 < 0.5;
  }
}
