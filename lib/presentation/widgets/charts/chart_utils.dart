import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';

/// 차트에서 사용하는 유틸리티 함수 모음
class ChartUtils {
  /// 백분율 문자열('%' 기호)에서 숫자 값만 추출
  static double extractPercentValue(String percentString) {
    try {
      // 퍼센트 기호 제거 후 숫자만 추출
      // 문자열이 비어있거나 숫자로 변환할 수 없는 경우 0.0 반환
      if (percentString.isEmpty) {
        return 0.0;
      }

      // % 기호 제거
      String cleaned = percentString.replaceAll('%', '').trim();

      // 숫자로 변환 시도
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      // 어떤 예외가 발생하더라도 안전하게 0.0 반환
      return 0.0;
    }
  }

  /// 출석 상태별 색상 반환
  static Color getStatusColor(String status, BuildContext context) {
    switch (status) {
      case 'present':
        return AppColors.successColor;
      case 'late':
        return AppColors.warningColor;
      case 'absent':
        return AppColors.errorColor;
      case 'future':
        return Theme.of(context).disabledColor;
      default:
        return Colors.grey;
    }
  }

  /// 출석 상태 텍스트 반환
  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return '출석';
      case 'late':
        return '지각';
      case 'absent':
        return '결석';
      case 'future':
        return '예정';
      default:
        return '알 수 없음';
    }
  }
}
