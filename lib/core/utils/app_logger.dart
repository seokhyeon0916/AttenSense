import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'AttenSense';

  // 정보 로그
  static void i(String message) {
    if (kDebugMode) {
      print('[$_tag] INFO: $message');
    }
  }

  // 디버그 로그
  static void d(String message) {
    if (kDebugMode) {
      print('[$_tag] DEBUG: $message');
    }
  }

  // 경고 로그
  static void w(String message) {
    if (kDebugMode) {
      print('[$_tag] WARNING: $message');
    }
  }

  // 오류 로그
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[$_tag] ERROR: $message');
      if (error != null) {
        print('[$_tag] ERROR DETAILS: $error');
      }
      if (stackTrace != null) {
        print('[$_tag] STACK TRACE: $stackTrace');
      }
    }
  }
}
