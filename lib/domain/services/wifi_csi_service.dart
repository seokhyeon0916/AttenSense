import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Wi-Fi CSI 데이터를 처리하기 위한 서비스 클래스
class WifiCsiService {
  static const MethodChannel _channel = MethodChannel(
    'com.capston_design/wifi_csi',
  );

  // 싱글톤 패턴 구현
  static final WifiCsiService _instance = WifiCsiService._internal();
  factory WifiCsiService() => _instance;
  WifiCsiService._internal();

  final StreamController<Map<String, dynamic>> _csiDataStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// CSI 데이터 스트림을 가져옵니다.
  Stream<Map<String, dynamic>> get csiDataStream =>
      _csiDataStreamController.stream;

  /// CSI 데이터 수집을 시작합니다.
  Future<bool> startCsiCollection() async {
    try {
      final result = await _channel.invokeMethod<bool>('startCsiCollection');

      if (result == true) {
        // 네이티브 측에서 데이터를 수집하는 동안 이벤트 리스닝 설정
        _channel.setMethodCallHandler(_handleMethodCall);
      }

      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('CSI 데이터 수집 시작 실패: ${e.message}');
      return false;
    }
  }

  /// CSI 데이터 수집을 중지합니다.
  Future<bool> stopCsiCollection() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopCsiCollection');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('CSI 데이터 수집 중지 실패: ${e.message}');
      return false;
    }
  }

  /// 네이티브에서 전달받은 CSI 데이터를 처리합니다.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onCsiDataReceived':
        final csiData = Map<String, dynamic>.from(call.arguments);
        _csiDataStreamController.add(csiData);
        return true;
      default:
        return null;
    }
  }

  /// 디바이스가 Wi-Fi CSI 데이터 수집을 지원하는지 확인합니다.
  Future<bool> isDeviceSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceSupported');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('기기 지원 확인 실패: ${e.message}');
      return false;
    }
  }

  /// 수집된 CSI 데이터를 분석하여 출석 상태를 결정합니다.
  /// 반환값: present, late, absent, unknown 중 하나
  Future<String> analyzeAttendance(
    Map<String, dynamic> csiData,
    double threshold,
  ) async {
    try {
      // 간단한 예시 구현: 실제 구현은 머신러닝이나 더 복잡한 알고리즘이 필요합니다.
      final jsonData = jsonEncode(csiData);
      final result = await _channel.invokeMethod<String>('analyzeAttendance', {
        'csiData': jsonData,
        'threshold': threshold,
      });

      return result ?? 'unknown';
    } on PlatformException catch (e) {
      debugPrint('출석 분석 실패: ${e.message}');
      return 'unknown';
    }
  }

  /// 기록된 CSI 데이터를 기반으로 학생의 활동 수준을 추정합니다.
  Future<double> estimateActivityLevel(Map<String, dynamic> csiData) async {
    try {
      final jsonData = jsonEncode(csiData);
      final result = await _channel.invokeMethod<double>(
        'estimateActivityLevel',
        {'csiData': jsonData},
      );

      return result ?? 0.0;
    } on PlatformException catch (e) {
      debugPrint('활동 수준 추정 실패: ${e.message}');
      return 0.0;
    }
  }

  /// CSI 데이터를 사용하여 사용자의 현재 위치(강의실 내부인지 여부)를 확인합니다.
  Future<bool> isUserInClassroom(
    Map<String, dynamic> csiData,
    String classroomId,
  ) async {
    try {
      final jsonData = jsonEncode(csiData);
      final result = await _channel.invokeMethod<bool>('isUserInClassroom', {
        'csiData': jsonData,
        'classroomId': classroomId,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('위치 확인 실패: ${e.message}');
      return false;
    }
  }

  /// 마지막으로 수집된 Wi-Fi CSI 데이터를 가져옵니다.
  Future<Map<String, dynamic>?> getLastCsiData() async {
    try {
      final result = await _channel.invokeMethod<String>('getLastCsiData');

      if (result != null) {
        return jsonDecode(result) as Map<String, dynamic>;
      }

      return null;
    } on PlatformException catch (e) {
      debugPrint('마지막 CSI 데이터 조회 실패: ${e.message}');
      return null;
    }
  }

  /// 리소스 해제
  void dispose() {
    _csiDataStreamController.close();
  }
}
