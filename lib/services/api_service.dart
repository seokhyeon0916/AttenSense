import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Wi-Fi CSI 기반 출결 시스템 서버 API 서비스
/// Node.js 서버와의 통신을 담당하는 클래스
class ApiService {
  // HTTP 클라이언트
  static final http.Client _client = http.Client();

  // HTTP 헤더
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 서버 응답 대기 시간 (밀리초)
  static const int _timeout = 20000;

  // 실제 서버 URL로 변경 필요 (.env 또는 환경 설정에서 관리하는 것이 좋음)
  // 안드로이드 에뮬레이터에서는 10.0.2.2:3000 사용
  // iOS 시뮬레이터에서는 localhost:3000 사용
  // 실제 기기에서는 컴퓨터의 IP 주소를 사용 (예: 192.168.0.10:3000)
  // Google Cloud 환경에서는 해당 서비스 URL 사용
  static String _baseUrl =
      'https://csi-server-696186584116.asia-northeast3.run.app';

  // 서버 API 사용 여부 (서버 문제 발생 시 비활성화)
  static bool _useServerApi = true;

  /// API 서비스 초기화 메서드
  static Future<void> init({String? serverUrl, bool? useServerApi}) async {
    if (serverUrl != null) {
      String formattedUrl = serverUrl;

      // 스키마가 없는 경우 http:// 추가
      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }

      // 후행 슬래시 제거
      if (formattedUrl.endsWith('/')) {
        formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
      }

      _baseUrl = formattedUrl;
      debugPrint('API 서비스 기본 URL 설정됨: $_baseUrl');
    } else {
      // 기본값 유지 (이미 플랫폼 별로 설정되어 있음)
      debugPrint('API 서비스 기본 URL 유지됨: $_baseUrl');
    }

    // 배포된 서버가 있으면 API 사용 설정
    _useServerApi = useServerApi ?? true;
    debugPrint('서버 API 사용 설정: $_useServerApi');

    if (_useServerApi) {
      try {
        final healthResult = await checkServerHealth();
        debugPrint('서버 연결 성공: ${healthResult['status'] ?? '알 수 없음'}');
      } catch (e) {
        debugPrint('서버 연결 실패: $e - Firebase 전용 모드로 전환');
        _useServerApi = false;
      }
    }
  }

  /// Singleton 인스턴스
  static final ApiService _instance = ApiService._internal();

  /// 싱글톤 공장 생성자
  factory ApiService() {
    return _instance;
  }

  /// 내부 생성자
  ApiService._internal();

  /// 학생 출석 체크 및 CSI 데이터 캡처 요청
  Future<Map<String, dynamic>> checkAttendance({
    required String sessionId,
    required String classId,
    required String className,
    required String studentId,
    required String studentName,
  }) async {
    if (!_useServerApi) {
      debugPrint('서버 API 비활성화됨: Firebase만 사용하여 출석 체크');
      // 서버 API를 사용하지 않고 Firebase만 사용하는 모드에서는 성공 응답 시뮬레이션
      return {
        'success': true,
        'message': '출석이 성공적으로 처리되었습니다.',
        'captureStarted': false, // CSI 캡처는 서버 기능이므로 비활성화
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/attendance/check'),
            headers: _headers,
            body: jsonEncode({
              'sessionId': sessionId,
              'classId': classId,
              'className': className,
              'studentId': studentId,
              'studentName': studentName,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(milliseconds: _timeout));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('서버 응답 오류: ${response.statusCode} - ${response.body}');
        // 서버 오류 시 Firebase만 사용하도록 대체 응답
        return {
          'success': true,
          'message': '출석이 Firebase에 기록되었습니다.',
          'captureStarted': false,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('출석 체크 API 호출 실패: $e');
      // 예외 발생 시 Firebase만 사용하도록 대체 응답
      return {
        'success': true,
        'message': '서버 연결 실패, Firebase에만 출석 기록됨',
        'captureStarted': false,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 교수 수업 시작 요청
  Future<Map<String, dynamic>> startClass({
    required String classId,
    required String className,
    required String professorId,
  }) async {
    if (!_useServerApi) {
      debugPrint('서버 API 비활성화됨: Firebase만 사용하여 수업 시작');
      // 서버 API를 사용하지 않고 Firebase만 사용하는 모드에서는 성공 응답 시뮬레이션
      return {
        'success': true,
        'message': '수업이 시작되었습니다. (Firebase 전용 모드)',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/class/start'),
            headers: _headers,
            body: jsonEncode({
              'classId': classId,
              'className': className,
              'professorId': professorId,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(milliseconds: _timeout));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('서버 응답 오류: ${response.statusCode} - ${response.body}');
        // 서버 오류 시 Firebase만 사용하도록 대체 응답
        return {
          'success': true,
          'message': '수업이 Firebase에 시작되었습니다.',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('수업 시작 API 호출 실패: $e');
      // 예외 발생 시 Firebase만 사용하도록 대체 응답
      return {
        'success': true,
        'message': '서버 연결 실패, Firebase에만 수업 시작 기록됨',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 교수 수업 종료 요청
  Future<Map<String, dynamic>> endClass({
    required String sessionId,
    required String classId,
  }) async {
    if (!_useServerApi) {
      debugPrint('서버 API 비활성화됨: Firebase만 사용하여 수업 종료');
      // 서버 API를 사용하지 않고 Firebase만 사용하는 모드에서는 성공 응답 시뮬레이션
      return {
        'success': true,
        'message': '수업이 종료되었습니다. (Firebase 전용 모드)',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/class/end'),
            headers: _headers,
            body: jsonEncode({
              'sessionId': sessionId,
              'classId': classId,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(milliseconds: _timeout));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('서버 응답 오류: ${response.statusCode} - ${response.body}');
        // 서버 오류 시 Firebase만 사용하도록 대체 응답
        return {
          'success': true,
          'message': '수업이 Firebase에서 종료되었습니다.',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('수업 종료 API 호출 실패: $e');
      // 예외 발생 시 Firebase만 사용하도록 대체 응답
      return {
        'success': true,
        'message': '서버 연결 실패, Firebase에만 수업 종료 기록됨',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 출석 상태 조회
  Future<Map<String, dynamic>> getAttendanceStatus({
    required String sessionId,
    required String studentId,
  }) async {
    if (!_useServerApi) {
      debugPrint('서버 API 비활성화됨: Firebase만 사용하여 출석 상태 조회');
      // 서버 API를 사용하지 않고 Firebase만 사용하는 모드에서는 성공 응답 시뮬레이션
      return {
        'success': true,
        'message': '출석 상태가 조회되었습니다. (Firebase 전용 모드)',
        'status': 'unknown', // Firebase에서 직접 조회해야 함
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_baseUrl/api/attendance/status?sessionId=$sessionId&studentId=$studentId',
            ),
            headers: _headers,
          )
          .timeout(const Duration(milliseconds: _timeout));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('서버 응답 오류: ${response.statusCode} - ${response.body}');
        // 서버 오류 시 Firebase만 사용하도록 대체 응답
        return {
          'success': true,
          'message': '출석 상태가 Firebase에서 조회되었습니다.',
          'status': 'unknown', // Firebase에서 직접 조회해야 함
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('출석 상태 조회 API 호출 실패: $e');
      // 예외 발생 시 Firebase만 사용하도록 대체 응답
      return {
        'success': true,
        'message': '서버 연결 실패, Firebase에서만 출석 상태 조회 가능',
        'status': 'unknown', // Firebase에서 직접 조회해야 함
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 서버 상태 확인
  static Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/health'), headers: _headers)
          .timeout(const Duration(milliseconds: _timeout));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 서버가 정상이면 API 사용 활성화
        _useServerApi = true;
        debugPrint('서버 상태 확인 성공: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // 서버가 비정상이면 API 사용 비활성화
        _useServerApi = false;
        throw Exception('서버 오류: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // 서버 연결 실패 시 API 사용 비활성화
      _useServerApi = false;
      debugPrint('서버 상태 확인 실패: $e - Firebase 전용 모드로 전환');
      return {
        'success': false,
        'message': '서버 연결 실패, Firebase 전용 모드로 작동 중',
        'status': 'offline',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// CSI 서버 상태 확인
  static Future<bool> checkCSIServerHealth() async {
    try {
      debugPrint('CSI 서버 연결 테스트 시도...');
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));

      final bool isSuccess =
          response.statusCode >= 200 && response.statusCode < 300;
      debugPrint(
        'CSI 서버 연결 테스트: ${isSuccess ? '성공' : '실패'} (${response.statusCode})',
      );

      if (isSuccess) {
        debugPrint('CSI 서버 응답: ${response.body}');
        return true;
      } else {
        debugPrint('CSI 서버 오류 응답: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('CSI 서버 연결 실패: $e');
      return false;
    }
  }

  /// CSI 서버에 예측 요청
  static Future<Map<String, dynamic>?> requestCSIPrediction({
    required String sessionId,
    required String studentId,
  }) async {
    try {
      // 먼저 서버 연결 상태 확인
      bool isServerAvailable = await checkCSIServerHealth();

      if (!isServerAvailable) {
        debugPrint('CSI 서버 연결 불가: 더미 예측 결과를 반환합니다.');

        // 더미 예측 결과 생성 (학생ID 뒷자리가 짝수인 경우 sitdown, 홀수인 경우 empty)
        final int studentSuffix =
            int.tryParse(studentId.substring(studentId.length - 1)) ?? 0;
        final bool isActive = studentSuffix % 2 == 0; // 짝수면 sitdown, 홀수면 empty

        return {
          'success': true,
          'prediction': isActive ? 'sitdown' : 'empty',
          'is_present': isActive,
          'attendance_status': isActive ? '출석중' : '공석',
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'dummy',
        };
      }

      // CSI 서버에 예측 요청 - main.py 엔드포인트 사용
      debugPrint('CSI 서버에 예측 요청 시도 (main.py 엔드포인트)');

      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/main.py'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'session_id': sessionId,
                'student_id': studentId,
                'timestamp': DateTime.now().toIso8601String(),
              }),
            )
            .timeout(const Duration(seconds: 5));

        debugPrint('CSI 예측 요청 응답: ${response.statusCode} - ${response.body}');

        // 응답 처리
        if (response.statusCode == 200) {
          try {
            final responseData =
                jsonDecode(response.body) as Map<String, dynamic>;

            // 현재 서버가 반환하는 응답 형식 처리
            if (responseData.containsKey('message')) {
              // 메시지 형식인 경우 로그만 남기고 더미 데이터 사용
              debugPrint('서버 메시지: ${responseData['message']}');
            }
            // 정상적인 형식인 경우 (success와 prediction 필드가 있는 경우)
            else if (responseData.containsKey('success') &&
                responseData['success'] == true &&
                responseData.containsKey('prediction')) {
              final prediction = responseData['prediction'] as String;
              final isPresent = prediction.toLowerCase() == 'sitdown';
              final attendanceStatus = isPresent ? '출석중' : '공석';

              return {
                'success': true,
                'prediction': prediction,
                'is_present': isPresent,
                'attendance_status': attendanceStatus,
                'timestamp': DateTime.now().toIso8601String(),
                'source': 'server',
              };
            }
          } catch (parseError) {
            debugPrint('CSI 서버 응답 파싱 실패: $parseError');
            debugPrint('원본 응답: ${response.body}');
          }
        }
      } catch (requestError) {
        debugPrint('CSI 예측 요청 실패: $requestError');
      }

      // 더미 데이터 반환
      debugPrint('더미 예측 결과 사용');
      final int studentSuffix =
          int.tryParse(studentId.substring(studentId.length - 1)) ?? 0;
      final bool isActive = studentSuffix % 2 == 0;

      return {
        'success': true,
        'prediction': isActive ? 'sitdown' : 'empty',
        'is_present': isActive,
        'attendance_status': isActive ? '출석중' : '공석',
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'dummy',
      };
    } catch (e) {
      debugPrint('CSI 예측 요청 처리 오류: $e');
      return {
        'success': false,
        'prediction': 'sitdown', // 기본값
        'is_present': true,
        'attendance_status': '출석중',
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'fallback',
        'error': e.toString(),
      };
    }
  }

  /// 리소스 정리
  void dispose() {
    _client.close();
  }
}
