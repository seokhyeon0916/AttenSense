import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/colors.dart';
import 'dart:convert';

/// 서버 연결 테스트 화면
class ServerTestScreen extends StatefulWidget {
  const ServerTestScreen({super.key});

  @override
  _ServerTestScreenState createState() => _ServerTestScreenState();
}

class _ServerTestScreenState extends State<ServerTestScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _responseText = '서버 연결 테스트를 시작하세요';
  final TextEditingController _serverUrlController = TextEditingController();

  // 테스트 데이터
  final String _testClassId = 'test_class_001';
  final String _testClassName = '테스트 수업';
  final String _testProfessorId = 'prof_001';
  final String _testStudentId = 'student_001';
  final String _testStudentName = '홍길동';
  String? _testSessionId;

  @override
  void initState() {
    super.initState();
    // 기본 서버 URL 설정
    _serverUrlController.text =
        'https://wildcat-noted-noticeably.ngrok-free.app/';
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  // 서버 URL 업데이트
  void _updateServerUrl() {
    final inputUrl = _serverUrlController.text.trim();

    if (inputUrl.isEmpty) {
      // 빈 값이면 기본값으로 재설정
      ApiService.init();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버 URL이 기본값으로 재설정되었습니다.'),
          backgroundColor: AppColors.successColor,
        ),
      );
      return;
    }

    // URL 형식 확인 (ApiService.init()에서 처리하지만 사용자에게 피드백 제공)
    String formattedUrl = inputUrl;
    bool urlChanged = false;

    if (!inputUrl.startsWith('http://') && !inputUrl.startsWith('https://')) {
      formattedUrl = 'http://$inputUrl';
      urlChanged = true;
    }

    // URL 설정
    ApiService.init(serverUrl: formattedUrl);

    // 피드백 제공
    if (urlChanged) {
      _serverUrlController.text = formattedUrl; // 텍스트 필드 업데이트
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '서버 URL이 $formattedUrl(으)로 업데이트되었습니다. (http:// 자동 추가됨)',
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('서버 URL이 $formattedUrl(으)로 업데이트되었습니다.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  // 서버 상태 확인
  Future<void> _checkServerHealth() async {
    setState(() {
      _isLoading = true;
      _responseText = '서버 상태 확인 중...';
    });

    try {
      final response = await ApiService.checkServerHealth();
      setState(() {
        _isLoading = false;
        _responseText = '서버 상태: ${prettyJson(response)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = '서버 상태 확인 실패: $e';
      });
    }
  }

  // 수업 시작 테스트
  Future<void> _testStartClass() async {
    setState(() {
      _isLoading = true;
      _responseText = '수업 시작 요청 중...';
    });

    try {
      final response = await _apiService.startClass(
        classId: _testClassId,
        className: _testClassName,
        professorId: _testProfessorId,
      );

      // 세션 ID 저장
      _testSessionId = response['sessionId'];

      setState(() {
        _isLoading = false;
        _responseText = '수업 시작 성공: ${prettyJson(response)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = '수업 시작 실패: $e';
      });
    }
  }

  // 출석 체크 테스트
  Future<void> _testCheckAttendance() async {
    if (_testSessionId == null) {
      setState(() {
        _responseText = '먼저 수업을 시작해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = '출석 체크 요청 중...';
    });

    try {
      final response = await _apiService.checkAttendance(
        sessionId: _testSessionId!,
        classId: _testClassId,
        className: _testClassName,
        studentId: _testStudentId,
        studentName: _testStudentName,
      );
      setState(() {
        _isLoading = false;
        _responseText = '출석 체크 성공: ${prettyJson(response)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = '출석 체크 실패: $e';
      });
    }
  }

  // 출석 상태 조회 테스트
  Future<void> _testGetAttendanceStatus() async {
    if (_testSessionId == null) {
      setState(() {
        _responseText = '먼저 수업을 시작해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = '출석 상태 조회 중...';
    });

    try {
      final response = await _apiService.getAttendanceStatus(
        sessionId: _testSessionId!,
        studentId: _testStudentId,
      );
      setState(() {
        _isLoading = false;
        _responseText = '출석 상태 조회 성공: ${prettyJson(response)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = '출석 상태 조회 실패: $e';
      });
    }
  }

  // 수업 종료 테스트
  Future<void> _testEndClass() async {
    if (_testSessionId == null) {
      setState(() {
        _responseText = '먼저 수업을 시작해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = '수업 종료 요청 중...';
    });

    try {
      final response = await _apiService.endClass(
        sessionId: _testSessionId!,
        classId: _testClassId,
      );
      setState(() {
        _isLoading = false;
        _responseText = '수업 종료 성공: ${prettyJson(response)}';
        _testSessionId = null; // 세션 ID 초기화
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = '수업 종료 실패: $e';
      });
    }
  }

  // JSON을 보기 좋게 출력
  String prettyJson(Map<String, dynamic> json) {
    var encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('서버 연결 테스트')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 서버 URL 입력 필드
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: '서버 URL',
                hintText: 'http://10.50.205.133:3000',
                helperText: '형식: http://호스트명:포트번호 (http:// 누락 시 자동 추가됨)',
                helperMaxLines: 2,
                errorMaxLines: 2,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.language),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _updateServerUrl,
                  tooltip: '서버 URL 업데이트',
                ),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _updateServerUrl(),
              autocorrect: false,
            ),
            const SizedBox(height: 16),

            // 테스트 케이스 버튼들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkServerHealth,
                  child: const Text('서버 상태 확인'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testStartClass,
                  child: const Text('수업 시작'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading || _testSessionId == null
                          ? null
                          : _testCheckAttendance,
                  child: const Text('출석 체크'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading || _testSessionId == null
                          ? null
                          : _testGetAttendanceStatus,
                  child: const Text('출석 상태 조회'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading || _testSessionId == null
                          ? null
                          : _testEndClass,
                  child: const Text('수업 종료'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              '응답 결과:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // 응답 결과 출력
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SelectableText(
                        _responseText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
            ),

            const SizedBox(height: 16),

            // 테스트 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '테스트 정보',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('클래스 ID: $_testClassId'),
                    Text('클래스명: $_testClassName'),
                    Text('교수 ID: $_testProfessorId'),
                    Text('학생 ID: $_testStudentId'),
                    Text('학생 이름: $_testStudentName'),
                    if (_testSessionId != null)
                      Text(
                        '세션 ID: $_testSessionId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
