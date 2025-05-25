import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 다이얼로그 유틸리티 클래스
///
/// 다양한 다이얼로그 및 알림창을 표시하는 메서드를 제공합니다.
class DialogUtils {
  /// 확인 다이얼로그 표시
  ///
  /// [context] 빌드 컨텍스트
  /// [title] 다이얼로그 제목
  /// [message] 다이얼로그 메시지
  /// [confirmText] 확인 버튼 텍스트 (기본값: '확인')
  /// [cancelText] 취소 버튼 텍스트 (기본값: '취소')
  /// [onConfirm] 확인 버튼 클릭 핸들러
  /// [onCancel] 취소 버튼 클릭 핸들러
  /// [barrierDismissible] 배경 클릭으로 닫기 가능 여부
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 16.0,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  if (onCancel != null) {
                    onCancel();
                  }
                },
                child: Text(
                  cancelText,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  if (onConfirm != null) {
                    onConfirm();
                  }
                },
                child: Text(
                  confirmText,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor:
                isDarkMode ? const Color(0xFF303030) : Colors.white,
            elevation: 4.0,
          ),
    );

    return result ?? false;
  }

  /// 알림 다이얼로그 표시
  ///
  /// [context] 빌드 컨텍스트
  /// [title] 다이얼로그 제목
  /// [message] 다이얼로그 메시지
  /// [buttonText] 버튼 텍스트 (기본값: '확인')
  /// [onConfirm] 확인 버튼 클릭 핸들러
  /// [barrierDismissible] 배경 클릭으로 닫기 가능 여부
  static Future<void> showAlertDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = '확인',
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 16.0,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onConfirm != null) {
                    onConfirm();
                  }
                },
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor:
                isDarkMode ? const Color(0xFF303030) : Colors.white,
            elevation: 4.0,
          ),
    );
  }

  /// 입력 다이얼로그 표시
  ///
  /// [context] 빌드 컨텍스트
  /// [title] 다이얼로그 제목
  /// [hintText] 입력 필드 힌트 텍스트
  /// [initialValue] 초기 입력값
  /// [confirmText] 확인 버튼 텍스트 (기본값: '확인')
  /// [cancelText] 취소 버튼 텍스트 (기본값: '취소')
  /// [validator] 입력값 유효성 검사 함수
  /// [keyboardType] 키보드 타입
  /// [maxLength] 최대 입력 길이
  /// [obscureText] 비밀번호 입력 여부
  /// [barrierDismissible] 배경 클릭으로 닫기 가능 여부
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    String? initialValue,
    String confirmText = '확인',
    String cancelText = '취소',
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
    bool barrierDismissible = true,
  }) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor:
                      isDarkMode
                          ? Colors.white10
                          : Colors.black.withAlpha((0.05 * 255).round()),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: keyboardType,
                maxLength: maxLength,
                obscureText: obscureText,
                validator: validator,
                onFieldSubmitted: (value) {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(controller.text);
                  }
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  cancelText,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(controller.text);
                  }
                },
                child: Text(
                  confirmText,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor:
                isDarkMode ? const Color(0xFF303030) : Colors.white,
            elevation: 4.0,
          ),
    );

    return result;
  }

  /// 아이콘이 있는 알림 다이얼로그 표시
  ///
  /// [context] 빌드 컨텍스트
  /// [title] 다이얼로그 제목
  /// [message] 다이얼로그 메시지
  /// [icon] 아이콘
  /// [iconColor] 아이콘 색상
  /// [buttonText] 버튼 텍스트 (기본값: '확인')
  /// [onConfirm] 확인 버튼 클릭 핸들러
  /// [barrierDismissible] 배경 클릭으로 닫기 가능 여부
  static Future<void> showIconDialog({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    Color? iconColor,
    String buttonText = '확인',
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color effectiveIconColor = iconColor ?? theme.primaryColor;

    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (BuildContext context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48.0, color: effectiveIconColor),
                ),
                const SizedBox(height: 24.0),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onConfirm != null) {
                        onConfirm();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: effectiveIconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.all(24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor:
                isDarkMode ? const Color(0xFF303030) : Colors.white,
            elevation: 4.0,
          ),
    );
  }

  /// 작업 메뉴 다이얼로그 표시
  ///
  /// [context] 빌드 컨텍스트
  /// [title] 다이얼로그 제목 (선택사항)
  /// [actions] 작업 목록
  /// [cancelText] 취소 버튼 텍스트 (기본값: '취소')
  static Future<int?> showActionSheet({
    required BuildContext context,
    String? title,
    required List<ActionSheetItem> actions,
    String cancelText = '취소',
  }) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // iOS 스타일 액션 시트 (CupertinoActionSheet)
    if (theme.platform == TargetPlatform.iOS) {
      return showCupertinoModalPopup<int>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title:
                title != null
                    ? Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    )
                    : null,
            actions:
                actions.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final ActionSheetItem action = entry.value;

                  return CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(context).pop(index);
                    },
                    isDestructiveAction: action.isDestructive,
                    isDefaultAction: action.isDefault,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (action.icon != null) ...[
                          Icon(
                            action.icon,
                            color:
                                action.isDestructive
                                    ? CupertinoColors.destructiveRed
                                    : action.iconColor ?? theme.primaryColor,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        Text(
                          action.title,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight:
                                action.isDefault
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      );
    }

    // 안드로이드 스타일 액션 시트 (BottomSheet)
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF303030) : Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                const Divider(),
              ],
              ...actions.asMap().entries.map((entry) {
                final int index = entry.key;
                final ActionSheetItem action = entry.value;

                return ListTile(
                  leading:
                      action.icon != null
                          ? Icon(
                            action.icon,
                            color:
                                action.isDestructive
                                    ? theme.colorScheme.error
                                    : action.iconColor ?? theme.primaryColor,
                          )
                          : null,
                  title: Text(
                    action.title,
                    style: TextStyle(
                      color:
                          action.isDestructive
                              ? theme.colorScheme.error
                              : isDarkMode
                              ? Colors.white
                              : Colors.black87,
                      fontWeight:
                          action.isDefault
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(index);
                  },
                );
              }),
              const Divider(),
              ListTile(
                title: Text(
                  cancelText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 로딩 다이얼로그 표시
  ///
  /// [context] 빌드 컨텍스트
  /// [message] 로딩 메시지
  static Future<void> showLoadingDialog({
    required BuildContext context,
    String message = '로딩 중...',
  }) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => AlertDialog(
            content: Row(
              children: <Widget>[
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
                const SizedBox(width: 20.0),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor:
                isDarkMode ? const Color(0xFF303030) : Colors.white,
            elevation: 4.0,
          ),
    );
  }

  /// 토스트 메시지 표시
  ///
  /// [context] 빌드 컨텍스트
  /// [message] 토스트 메시지
  /// [duration] 표시 시간 (기본값: 2초)
  /// [backgroundColor] 배경색
  /// [textColor] 텍스트 색상
  /// [position] 위치 (기본값: 하단)
  static void showToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    Color? textColor,
    ToastPosition position = ToastPosition.bottom,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color effectiveBackgroundColor =
        backgroundColor ?? (isDarkMode ? Colors.grey[800]! : Colors.grey[900]!);
    final Color effectiveTextColor =
        textColor ?? (isDarkMode ? Colors.white : Colors.white);

    final OverlayState overlayState = Overlay.of(context);

    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        // 위치에 따른 정렬 변수 선언 - nullable로 선언
        double? top;
        double? bottom;

        switch (position) {
          case ToastPosition.top:
            top = 50.0;
            bottom = null;
            break;
          case ToastPosition.center:
            top = 0.0;
            bottom = 0.0;
            break;
          case ToastPosition.bottom:
            top = null;
            bottom = 50.0;
            break;
        }

        return Positioned(
          top: top,
          bottom: bottom,
          left: 24.0,
          right: 24.0,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Align(
                alignment:
                    position == ToastPosition.top
                        ? Alignment.topCenter
                        : position == ToastPosition.center
                        ? Alignment.center
                        : Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveBackgroundColor,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        offset: const Offset(0, 2),
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: effectiveTextColor, fontSize: 14.0),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

/// 액션 시트 항목 클래스
class ActionSheetItem {
  /// 항목 제목
  final String title;

  /// 항목 아이콘
  final IconData? icon;

  /// 아이콘 색상
  final Color? iconColor;

  /// 파괴적 액션 여부
  final bool isDestructive;

  /// 기본 액션 여부
  final bool isDefault;

  /// 액션 시트 항목 생성자
  const ActionSheetItem({
    required this.title,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

/// 토스트 위치 열거형
enum ToastPosition {
  /// 상단
  top,

  /// 중앙
  center,

  /// 하단
  bottom,
}
