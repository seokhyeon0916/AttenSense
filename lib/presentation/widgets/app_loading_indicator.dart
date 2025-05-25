import 'package:flutter/material.dart';

/// 앱 전반에서 일관된 로딩 상태를 표시하기 위한 위젯
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 36.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              strokeWidth: 3.0,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16.0),
            Text(
              message!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
