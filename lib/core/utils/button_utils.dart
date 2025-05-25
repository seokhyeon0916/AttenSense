import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 앱 버튼 유형 정의
enum AppButtonType {
  /// 기본 버튼 (색상이 채워진 버튼)
  primary,

  /// 테두리만 있는 버튼
  outline,

  /// 텍스트만 있는 버튼
  text,

  /// 아이콘 버튼
  icon,

  /// 그라데이션 배경 버튼
  gradient,
}

/// 버튼 크기 정의
enum AppButtonSize {
  /// 큰 크기 버튼
  large,

  /// 중간 크기 버튼
  medium,

  /// 작은 크기 버튼
  small,
}

/// 앱에서 사용하는 기본 버튼 컴포넌트
///
/// 다양한 버튼 유형과, 크기를 지원하는 재사용 가능한 버튼 위젯입니다.
class AppButton extends StatelessWidget {
  /// 버튼 라벨
  final String label;

  /// 버튼 클릭 핸들러
  final VoidCallback? onPressed;

  /// 버튼 유형
  final AppButtonType type;

  /// 버튼 크기
  final AppButtonSize size;

  /// 버튼 아이콘 (선택사항)
  final IconData? icon;

  /// 아이콘 위치 (기본값: 왼쪽)
  final bool iconRight;

  /// 버튼 배경색 (기본값: 테마 주 색상)
  final Color? backgroundColor;

  /// 버튼 텍스트 색상 (기본값: 자동)
  final Color? textColor;

  /// 버튼 테두리 색상 (outline 유형용)
  final Color? borderColor;

  /// 버튼 너비 (기본값: 자동)
  final double? width;

  /// 버튼 높이 (기본값: 크기에 따라 자동)
  final double? height;

  /// 그라데이션 색상 (gradient 유형용)
  final List<Color>? gradientColors;

  /// 버튼 로딩 상태 표시
  final bool isLoading;

  /// 버튼 비활성화 상태
  final bool disabled;

  /// 버튼 둥근 모서리 정도
  final double? borderRadius;

  /// 그림자 강도 (기본값: 0)
  final double elevation;

  /// 버튼 패딩 (기본값: 크기에 따라 자동)
  final EdgeInsetsGeometry? padding;

  /// 기본 버튼 생성자
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.gradientColors,
    this.isLoading = false,
    this.disabled = false,
    this.borderRadius,
    this.elevation = 0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final bool effectiveDisabled = disabled || isLoading;

    // 크기에 따른 속성 설정
    double effectiveHeight;
    double effectiveFontSize;
    double effectiveIconSize;
    EdgeInsetsGeometry effectivePadding;

    switch (size) {
      case AppButtonSize.large:
        effectiveHeight = height ?? 56.0;
        effectiveFontSize = 16.0;
        effectiveIconSize = 24.0;
        effectivePadding =
            padding ??
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
        break;

      case AppButtonSize.medium:
        effectiveHeight = height ?? 44.0;
        effectiveFontSize = 14.0;
        effectiveIconSize = 20.0;
        effectivePadding =
            padding ??
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);
        break;

      case AppButtonSize.small:
        effectiveHeight = height ?? 36.0;
        effectiveFontSize = 13.0;
        effectiveIconSize = 16.0;
        effectivePadding =
            padding ??
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
        break;
    }

    // 버튼 색상 설정
    final Color effectiveBackgroundColor =
        backgroundColor ??
        (type == AppButtonType.primary
            ? theme.primaryColor
            : Colors.transparent);

    final Color effectiveBorderColor =
        borderColor ??
        (type == AppButtonType.outline
            ? theme.primaryColor
            : Colors.transparent);

    Color effectiveTextColor =
        textColor ??
        (type == AppButtonType.primary
            ? theme.primaryColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white
            : type == AppButtonType.text || type == AppButtonType.outline
            ? theme.primaryColor
            : isDarkMode
            ? Colors.white
            : Colors.black87);

    if (effectiveDisabled) {
      final int alpha = (0.5 * 255).round();
      effectiveTextColor = effectiveTextColor.withAlpha(alpha);
    }

    // 버튼 둥글기 설정
    final double effectiveBorderRadius = borderRadius ?? 8.0;

    // 버튼 내용 위젯
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !iconRight) ...[
          Icon(icon, color: effectiveTextColor, size: effectiveIconSize),
          const SizedBox(width: 8.0),
        ],
        if (isLoading)
          SizedBox(
            width: effectiveIconSize,
            height: effectiveIconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          )
        else
          Text(
            label,
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w500,
              color: effectiveTextColor,
            ),
          ),
        if (icon != null && iconRight) ...[
          const SizedBox(width: 8.0),
          Icon(icon, color: effectiveTextColor, size: effectiveIconSize),
        ],
      ],
    );

    // 버튼 위젯 구현
    Widget buttonWidget;

    switch (type) {
      case AppButtonType.gradient:
        if (gradientColors == null || gradientColors!.length < 2) {
          throw ArgumentError('그라데이션 버튼은 최소 2개의 색상이 필요합니다.');
        }

        buttonWidget = Container(
          width: width,
          height: effectiveHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors!,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            boxShadow:
                elevation > 0
                    ? [
                      BoxShadow(
                        color: gradientColors!.last.withAlpha(
                          (0.3 * 255).round(),
                        ),
                        offset: const Offset(0, 2),
                        blurRadius: 6.0,
                        spreadRadius: 0,
                      ),
                    ]
                    : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: effectiveDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              splashColor: Colors.white.withAlpha((0.2 * 255).round()),
              child: Center(
                child: Padding(padding: effectivePadding, child: buttonContent),
              ),
            ),
          ),
        );
        break;

      case AppButtonType.primary:
        buttonWidget = ElevatedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: effectiveTextColor,
            padding: effectivePadding,
            elevation: elevation,
            shadowColor: effectiveBackgroundColor.withAlpha(
              (0.5 * 255).round(),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
            ),
            disabledBackgroundColor: effectiveBackgroundColor.withAlpha(
              (0.6 * 255).round(),
            ),
            minimumSize: Size(width ?? 0, effectiveHeight),
          ),
          child: buttonContent,
        );
        break;

      case AppButtonType.outline:
        buttonWidget = OutlinedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveTextColor,
            side: BorderSide(
              color:
                  effectiveDisabled
                      ? effectiveBorderColor.withAlpha((0.5 * 255).round())
                      : effectiveBorderColor,
              width: 1.5,
            ),
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
            ),
            minimumSize: Size(width ?? 0, effectiveHeight),
          ),
          child: buttonContent,
        );
        break;

      case AppButtonType.text:
        buttonWidget = TextButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: effectiveTextColor,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
            ),
            minimumSize: Size(width ?? 0, effectiveHeight),
          ),
          child: buttonContent,
        );
        break;

      case AppButtonType.icon:
        buttonWidget = IconButton(
          onPressed: effectiveDisabled ? null : onPressed,
          icon: Icon(
            icon,
            color:
                effectiveDisabled
                    ? effectiveTextColor.withAlpha((0.5 * 255).round())
                    : effectiveTextColor,
            size: effectiveIconSize,
          ),
          splashRadius: effectiveHeight / 2,
          padding: effectivePadding,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.disabled)) {
                return effectiveBackgroundColor.withAlpha((0.1 * 255).round());
              }
              return effectiveBackgroundColor;
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveBorderRadius),
              ),
            ),
          ),
        );
        break;
    }

    if (width != null && type != AppButtonType.icon) {
      buttonWidget = SizedBox(width: width, child: buttonWidget);
    }

    return buttonWidget;
  }
}

/// 전체 너비 버튼 컴포넌트
///
/// 부모 컨테이너의 전체 너비를 차지하는 버튼입니다.
class AppButtonFullWidth extends StatelessWidget {
  /// 버튼 라벨
  final String label;

  /// 버튼 클릭 핸들러
  final VoidCallback? onPressed;

  /// 버튼 유형
  final AppButtonType type;

  /// 버튼 크기
  final AppButtonSize size;

  /// 버튼 아이콘 (선택사항)
  final IconData? icon;

  /// 아이콘 위치 (기본값: 왼쪽)
  final bool iconRight;

  /// 버튼 배경색 (기본값: 테마 주 색상)
  final Color? backgroundColor;

  /// 버튼 텍스트 색상 (기본값: 자동)
  final Color? textColor;

  /// 버튼 테두리 색상 (outline 유형용)
  final Color? borderColor;

  /// 버튼 높이 (기본값: 크기에 따라 자동)
  final double? height;

  /// 그라데이션 색상 (gradient 유형용)
  final List<Color>? gradientColors;

  /// 버튼 로딩 상태 표시
  final bool isLoading;

  /// 버튼 비활성화 상태
  final bool disabled;

  /// 버튼 둥근 모서리 정도
  final double? borderRadius;

  /// 그림자 강도 (기본값: 0)
  final double elevation;

  /// 버튼 마진 (기본값: 없음)
  final EdgeInsetsGeometry margin;

  /// 전체 너비 버튼 생성자
  const AppButtonFullWidth({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.height,
    this.gradientColors,
    this.isLoading = false,
    this.disabled = false,
    this.borderRadius,
    this.elevation = 0,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: AppButton(
        label: label,
        onPressed: onPressed,
        type: type,
        size: size,
        icon: icon,
        iconRight: iconRight,
        backgroundColor: backgroundColor,
        textColor: textColor,
        borderColor: borderColor,
        width: double.infinity,
        height: height,
        gradientColors: gradientColors,
        isLoading: isLoading,
        disabled: disabled,
        borderRadius: borderRadius,
        elevation: elevation,
      ),
    );
  }
}

/// 버튼 그룹 컴포넌트
///
/// 여러 버튼을 일관된 스타일로 함께 표시합니다.
class AppButtonGroup extends StatelessWidget {
  /// 버튼 위젯 리스트
  final List<Widget> buttons;

  /// 버튼 간격 (기본값: 12)
  final double spacing;

  /// 버튼 나열 방향 (기본값: 가로)
  final Axis direction;

  /// 그룹 정렬 (기본값: 중앙)
  final MainAxisAlignment alignment;

  /// 버튼 그룹 생성자
  const AppButtonGroup({
    super.key,
    required this.buttons,
    this.spacing = 12.0,
    this.direction = Axis.horizontal,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return direction == Axis.horizontal
        ? Row(
          mainAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: _buildChildren(),
        )
        : Column(
          mainAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: _buildChildren(),
        );
  }

  List<Widget> _buildChildren() {
    final List<Widget> children = [];

    for (int i = 0; i < buttons.length; i++) {
      children.add(buttons[i]);

      if (i < buttons.length - 1) {
        children.add(
          direction == Axis.horizontal
              ? SizedBox(width: spacing)
              : SizedBox(height: spacing),
        );
      }
    }

    return children;
  }
}
