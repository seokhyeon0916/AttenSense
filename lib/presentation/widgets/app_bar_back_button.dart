import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 일관된 뒤로가기 버튼 위젯
class AppBarBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;

  const AppBarBackButton({
    super.key,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new),
      color: color ?? Theme.of(context).appBarTheme.iconTheme?.color,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      tooltip: '뒤로 가기',
    );
  }
}