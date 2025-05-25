import 'package:flutter/material.dart';
import '../../core/constants/spacing.dart';

/// 앱 전반에서 일관된 구분선을 제공하는 위젯
class AppDivider extends StatelessWidget {
  final Color? color;
  final double height;
  final double thickness;
  final double indent;
  final double endIndent;
  final bool hasSpacing;

  const AppDivider({
    super.key,
    this.color,
    this.height = 1.0,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.hasSpacing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? theme.dividerColor;

    if (hasSpacing) {
      return Column(
        children: [
          SizedBox(height: AppSpacing.sm),
          Divider(
            color: dividerColor,
            height: height,
            thickness: thickness,
            indent: indent,
            endIndent: endIndent,
          ),
          SizedBox(height: AppSpacing.sm),
        ],
      );
    }

    return Divider(
      color: dividerColor,
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
