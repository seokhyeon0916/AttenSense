import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 일관된 간격을 정의하는 클래스
class AppSpacing {
  // 기본 간격
  static const double xs = 4.0;    // 매우 작은 간격
  static const double sm = 8.0;    // 작은 간격
  static const double md = 16.0;   // 중간 간격
  static const double lg = 24.0;   // 큰 간격
  static const double xl = 32.0;   // 매우 큰 간격
  static const double xxl = 48.0;  // 초대형 간격

  // 수직 간격을 위한 SizedBox 위젯
  static const Widget verticalSpaceXS = SizedBox(height: xs);
  static const Widget verticalSpaceSM = SizedBox(height: sm);
  static const Widget verticalSpaceMD = SizedBox(height: md);
  static const Widget verticalSpaceLG = SizedBox(height: lg);
  static const Widget verticalSpaceXL = SizedBox(height: xl);

  // 수평 간격을 위한 SizedBox 위젯
  static const Widget horizontalSpaceXS = SizedBox(width: xs);
  static const Widget horizontalSpaceSM = SizedBox(width: sm);
  static const Widget horizontalSpaceMD = SizedBox(width: md);
  static const Widget horizontalSpaceLG = SizedBox(width: lg);
  static const Widget horizontalSpaceXL = SizedBox(width: xl);

  // 패딩 값
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  // 마진 값
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);
}