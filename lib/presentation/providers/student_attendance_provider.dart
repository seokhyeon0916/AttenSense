import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_attendance_statistics_service.dart';
import '../../core/dependency_injection.dart' as di;

/// 학생용 출석 데이터를 관리하는 Provider 클래스
class StudentAttendanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic> _myAttendance = {};
  List<Map<String, dynamic>> _attendanceHistory = [];
  Map<String, Map<String, dynamic>> _weeklyAttendance = {};
  Map<String, dynamic> _studentStatistics = {};
  List<Map<String, dynamic>> _recentAttendance = [];
  Map<String, dynamic> _attendancePattern = {};
  StudentAttendanceStatisticsService? _statisticsService;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic> get myAttendance => _myAttendance;
  List<Map<String, dynamic>> get attendanceHistory => _attendanceHistory;
  Map<String, Map<String, dynamic>> get weeklyAttendance => _weeklyAttendance;
  Map<String, dynamic> get studentStatistics => _studentStatistics;
  List<Map<String, dynamic>> get recentAttendance => _recentAttendance;
  Map<String, dynamic> get attendancePattern => _attendancePattern;

  /// 생성자
  StudentAttendanceProvider() {
    // 서비스는 필요할 때 lazy 초기화
    _fetchMyAttendance();
    _fetchWeeklyAttendance();

    // 기본 더미 데이터로 초기화
    _initializeDummyData();
  }

  /// 더미 데이터 초기화 (Firebase 데이터가 없을 때)
  void _initializeDummyData() {
    _studentStatistics = {
      'studentId': 'student_001',
      'totalClasses': 2,
      'totalSessions': 25,
      'attendanceByStatus': {
        'present': 22,
        'late': 2,
        'absent': 1,
        'excused': 0,
      },
      'attendanceRate': 96,
      'classStatistics': [
        {
          'classId': 'capstone_design_2024',
          'className': '캡스톤 디자인',
          'totalSessions': 15,
          'attendanceRate': 93,
          'statusCounts': {'present': 13, 'late': 1, 'absent': 1, 'excused': 0},
        },
        {
          'classId': 'database_2024',
          'className': '데이터베이스 시스템',
          'totalSessions': 10,
          'attendanceRate': 100,
          'statusCounts': {'present': 9, 'late': 1, 'absent': 0, 'excused': 0},
        },
      ],
      'recentAttendance': [],
      'weeklyPattern': {
        'Monday': 5,
        'Tuesday': 3,
        'Wednesday': 8,
        'Thursday': 4,
        'Friday': 2,
      },
    };

    _attendancePattern = {
      'attendanceRate': 96,
      'gradeLevel': '우수',
      'recommendation': '매우 우수한 출석률을 유지하고 있습니다! 현재 습관을 계속 유지하세요.',
      'recentTrend': '상승',
      'weeklyPattern': {
        'Monday': 5,
        'Tuesday': 3,
        'Wednesday': 8,
        'Thursday': 4,
        'Friday': 2,
      },
      'improvementSuggestions': [
        '우수한 출석률을 유지하고 있습니다. 현재 습관을 계속 유지하세요',
        '꾸준한 출석으로 학업 성취도를 높여보세요',
      ],
    };

    // 최근 출석 기록 더미 데이터
    final now = DateTime.now();
    _recentAttendance = [
      {
        'className': '캡스톤 디자인',
        'date': now.subtract(const Duration(days: 1)),
        'status': 'present',
        'attendanceTime': now.subtract(const Duration(days: 1, hours: 1)),
      },
      {
        'className': '데이터베이스 시스템',
        'date': now.subtract(const Duration(days: 2)),
        'status': 'present',
        'attendanceTime': now.subtract(const Duration(days: 2, hours: 2)),
      },
      {
        'className': '캡스톤 디자인',
        'date': now.subtract(const Duration(days: 3)),
        'status': 'late',
        'attendanceTime': now.subtract(const Duration(days: 3, hours: 1)),
      },
      {
        'className': '데이터베이스 시스템',
        'date': now.subtract(const Duration(days: 5)),
        'status': 'present',
        'attendanceTime': now.subtract(const Duration(days: 5, hours: 2)),
      },
      {
        'className': '캡스톤 디자인',
        'date': now.subtract(const Duration(days: 7)),
        'status': 'present',
        'attendanceTime': now.subtract(const Duration(days: 7, hours: 1)),
      },
    ];
  }

  /// 내 출석 데이터 조회
  Future<void> _fetchMyAttendance() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: 실제 구현에서는 Firebase 등의 데이터베이스에서 학생용 출석 데이터를 가져옴
      await Future.delayed(const Duration(seconds: 1)); // 데이터베이스 요청 시뮬레이션

      // 임시 데이터
      _myAttendance = {
        'present': '32',
        'late': '2',
        'absent': '0',
        'rate': '94%',
        'totalClasses': 34,
        'remainingClasses': 10,
      };

      // 임시 출석 기록 데이터
      _attendanceHistory = [
        {
          'date': '2023-11-01',
          'className': '캡스톤 디자인',
          'status': 'present',
          'time': '09:05',
        },
        {
          'date': '2023-11-01',
          'className': '데이터베이스',
          'status': 'present',
          'time': '13:02',
        },
        {
          'date': '2023-10-30',
          'className': '캡스톤 디자인',
          'status': 'late',
          'time': '09:15',
        },
        {
          'date': '2023-10-30',
          'className': '데이터베이스',
          'status': 'present',
          'time': '13:00',
        },
      ];

      _errorMessage = '';
    } catch (e) {
      _errorMessage = '출석 데이터를 불러오는데 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 주차별 출석 데이터 조회
  Future<void> _fetchWeeklyAttendance() async {
    try {
      // TODO: 실제 구현에서는 Firebase 등의 데이터베이스에서 주차별 출석 데이터를 가져옴
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // 데이터베이스 요청 시뮬레이션

      // 임시 주차별 출석 데이터 (1-14주차)
      final Map<String, Map<String, dynamic>> weeklyData = {};

      // 캡스톤 디자인 수업
      for (int i = 1; i <= 14; i++) {
        String week = i.toString();
        String status = 'present'; // 기본값

        if (i == 3) status = 'late'; // 3주차는 지각
        if (i == 10) status = 'absent'; // 10주차는 결석
        if (i > 12) status = 'future'; // 미래 주차는 아직 진행되지 않음

        weeklyData['$week-capstone'] = {
          'week': week,
          'className': '캡스톤 디자인',
          'classId': 'cap_design_2023',
          'status': status,
          'date': '2023-03-${i < 10 ? '0$i' : i}',
          'note': status == 'absent' ? '개인 사유' : '',
        };
      }

      // 데이터베이스 수업
      for (int i = 1; i <= 14; i++) {
        String week = i.toString();
        String status = 'present'; // 기본값

        if (i == 5) status = 'late'; // 5주차는 지각
        if (i == 7) status = 'absent'; // 7주차는 결석
        if (i > 12) status = 'future'; // 미래 주차는 아직 진행되지 않음

        weeklyData['$week-database'] = {
          'week': week,
          'className': '데이터베이스',
          'classId': 'database_2023',
          'status': status,
          'date': '2023-03-${i < 10 ? '0$i' : i}',
          'note': status == 'absent' ? '병결' : '',
        };
      }

      _weeklyAttendance = weeklyData;
      notifyListeners();
    } catch (e) {
      _errorMessage = '주차별 출석 데이터를 불러오는데 실패했습니다: $e';
    }
  }

  /// 출석 데이터 새로고침
  Future<void> refreshMyAttendance() async {
    await _fetchMyAttendance();
    await _fetchWeeklyAttendance();
  }

  /// 내 출석 데이터 조회
  Map<String, dynamic> getMyAttendance() {
    return _myAttendance;
  }

  /// 특정 날짜의 출석 기록 조회
  List<Map<String, dynamic>> getAttendanceByDate(String date) {
    return _attendanceHistory
        .where((record) => record['date'] == date)
        .toList();
  }

  /// 특정 수업의 출석 기록 조회
  List<Map<String, dynamic>> getAttendanceByClass(String className) {
    return _attendanceHistory
        .where((record) => record['className'] == className)
        .toList();
  }

  /// 특정 수업의 주차별 출석 기록 조회
  List<Map<String, dynamic>> getWeeklyAttendanceByClass(String classId) {
    // classId에 해당하는 주차별 출석 데이터만 필터링
    final List<Map<String, dynamic>> result = [];

    for (int i = 1; i <= 14; i++) {
      final key =
          '$i-${classId == 'cap_design_2023' ? 'capstone' : 'database'}';
      if (_weeklyAttendance.containsKey(key)) {
        result.add(_weeklyAttendance[key]!);
      }
    }

    // 주차 순으로 정렬
    result.sort((a, b) => int.parse(a['week']).compareTo(int.parse(b['week'])));

    return result;
  }

  /// 모든 수업의 주차별 출석 기록 조회
  List<Map<String, dynamic>> getAllWeeklyAttendance() {
    // 모든 주차별 출석 데이터를 날짜 기준으로 정렬하여 반환
    final List<Map<String, dynamic>> result = [];

    _weeklyAttendance.forEach((key, value) {
      result.add(value);
    });

    // 날짜 기준으로 정렬
    result.sort((a, b) => a['date'].compareTo(b['date']));

    return result;
  }

  /// 특정 수업의 주차별 출석률 데이터 생성 (차트용)
  List<Map<String, dynamic>> getWeeklyAttendanceRateByClass(String classId) {
    final List<Map<String, dynamic>> weeklyData = getWeeklyAttendanceByClass(
      classId,
    );

    return weeklyData.map((weekData) {
      // 출석 상태에 따른 출석률 계산
      double rate = 0;
      switch (weekData['status']) {
        case 'present':
          rate = 100.0;
          break;
        case 'late':
          rate = 50.0;
          break;
        case 'absent':
          rate = 0.0;
          break;
        case 'future':
          rate = 0.0; // 미래 주차는 0%로 표시
          break;
      }

      return {
        'week': weekData['week'],
        'status': weekData['status'],
        'rate': '${rate.toStringAsFixed(1)}%',
        'date': weekData['date'],
      };
    }).toList();
  }

  /// 전체 출석 현황 통계 생성 (차트용)
  Map<String, int> getAttendanceSummary() {
    // 임시 데이터 사용 (실제로는 모든 주차 데이터를 분석하여 계산)
    final present = int.parse(_myAttendance['present']);
    final late = int.parse(_myAttendance['late']);
    final absent = int.parse(_myAttendance['absent']);

    return {
      'present': present,
      'late': late,
      'absent': absent,
      'total': present + late + absent,
    };
  }

  /// 월별 출석 현황 데이터 생성 (실제 데이터 기반)
  List<Map<String, dynamic>> getMonthlyAttendanceData() {
    // 실제로는 Firebase에서 월별 데이터를 가져와야 하지만
    // 현재는 최근 출석 기록을 기반으로 간단한 월별 데이터 생성
    Map<String, Map<String, int>> monthlyData = {};

    for (final record in _recentAttendance) {
      final date = record['date'] as DateTime;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final status = record['status'] as String;

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'present': 0,
          'late': 0,
          'absent': 0,
          'excused': 0,
        };
      }

      monthlyData[monthKey]![status] =
          (monthlyData[monthKey]![status] ?? 0) + 1;
    }

    // Map을 List로 변환하고 날짜순 정렬
    final result =
        monthlyData.entries.map((entry) {
          final total = entry.value.values.reduce((a, b) => a + b);
          final attended = entry.value['present']! + entry.value['late']!;
          final rate = total > 0 ? (attended / total * 100).round() : 0;

          return {
            'month': entry.key,
            'attendanceRate': rate,
            'totalSessions': total,
            'statusCounts': entry.value,
          };
        }).toList();

    result.sort(
      (a, b) => (a['month'] as String).compareTo(b['month'] as String),
    );
    return result;
  }

  /// 수강 과목 목록 조회
  List<Map<String, dynamic>> getClasses() {
    // 실제 데이터베이스에서 수강 과목 목록을 가져오는 로직을 구현해야 합니다.
    // 여기서는 임시로 하드코딩된 데이터를 반환합니다.
    return [
      {
        'id': 'cap_design_2023',
        'name': '캡스톤 디자인',
        'color': AppColors.successColor,
      },
      {
        'id': 'database_2023',
        'name': '데이터베이스',
        'color': AppColors.primaryColor,
      },
    ];
  }

  /// 특정 과목의 출석 수 조회
  Map<String, String> getAttendanceCountsByClass(String className) {
    // 실제 데이터베이스에서 출석 수를 가져오는 로직을 구현해야 합니다.
    // 여기서는 임시로 하드코딩된 데이터를 반환합니다.
    return {
      '출석': className == '캡스톤 디자인' ? '12' : '10',
      '지각': className == '캡스톤 디자인' ? '1' : '2',
      '결석': className == '캡스톤 디자인' ? '0' : '1',
    };
  }

  /// 학생의 수강 과목 목록을 데이터베이스에서 가져오는 메서드
  Future<List<Map<String, dynamic>>> fetchStudentClasses(
    String studentId,
  ) async {
    final firestore = FirebaseFirestore.instance;
    try {
      // Firestore에서 학생의 수강 과목을 가져오는 쿼리
      final querySnapshot =
          await firestore
              .collection('classes')
              .where('studentIds', arrayContains: studentId)
              .get();

      // 쿼리 결과를 수강 과목 목록으로 변환
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'color': AppColors.primaryColor, // 기본 색상 사용
        };
      }).toList();
    } catch (e) {
      print('수강 과목을 불러오는 데 실패했습니다: $e');
      return [];
    }
  }

  /// 학생 출석 통계 데이터 조회
  Future<void> fetchStudentStatistics(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 서비스가 초기화되지 않은 경우 새로 생성
      _statisticsService ??= StudentAttendanceStatisticsService();

      // 학생 개인 출석 통계 가져오기
      final statistics = await _statisticsService!
          .getStudentAttendanceStatistics(studentId);

      // 출석 패턴 분석 가져오기
      final pattern = await _statisticsService!.getStudentAttendancePattern(
        studentId,
      );

      // 실제 데이터가 있으면 사용, 없으면 더미 데이터 유지
      if (statistics['totalSessions'] > 0) {
        _studentStatistics = statistics;
        _attendancePattern = pattern;
        _recentAttendance =
            statistics['recentAttendance'] != null
                ? List<Map<String, dynamic>>.from(
                  statistics['recentAttendance'],
                )
                : [];
      }
      // 더미 데이터가 이미 있으므로 빈 데이터일 때는 유지

      _errorMessage = '';

      debugPrint('학생 출석 통계 로드 완료: ${_studentStatistics['attendanceRate']}%');
    } catch (e) {
      debugPrint('학생 출석 통계 조회 실패: $e - 더미 데이터 사용');

      // 오류 발생 시 더미 데이터 사용 (이미 초기화되어 있음)
      if (_studentStatistics.isEmpty) {
        _initializeDummyData();
      }

      // 오류 메시지는 표시하지 않음 (더미 데이터로 정상 동작)
      _errorMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 특정 수업의 상세 출석 기록 조회
  Future<List<Map<String, dynamic>>> getClassAttendanceHistory(
    String studentId,
    String classId,
  ) async {
    try {
      // 서비스가 초기화되지 않은 경우 새로 생성
      _statisticsService ??= StudentAttendanceStatisticsService();

      final history = await _statisticsService!
          .getStudentClassAttendanceHistory(studentId, classId);
      return history;
    } catch (e) {
      debugPrint('수업별 출석 기록 조회 실패: $e');
      return [];
    }
  }

  /// 출석 통계 새로고침
  Future<void> refreshStatistics(String studentId) async {
    await fetchStudentStatistics(studentId);
  }

  /// 전체 출석률 반환
  int getOverallAttendanceRate() {
    return _studentStatistics['attendanceRate'] ?? 0;
  }

  /// 출석률에 따른 등급 반환
  String getAttendanceGrade() {
    return _attendancePattern['gradeLevel'] ?? '정보 없음';
  }

  /// 추천 메시지 반환
  String getRecommendation() {
    return _attendancePattern['recommendation'] ?? '출석 데이터를 수집 중입니다.';
  }

  /// 수업별 출석 통계 반환
  List<Map<String, dynamic>> getClassStatistics() {
    final classStats = _studentStatistics['classStatistics'];
    return classStats != null
        ? List<Map<String, dynamic>>.from(classStats)
        : [];
  }

  /// 출석 상태별 카운트 반환
  Map<String, int> getAttendanceStatusCounts() {
    final statusCounts = _studentStatistics['attendanceByStatus'];
    return statusCounts != null
        ? Map<String, int>.from(statusCounts)
        : {'present': 0, 'late': 0, 'absent': 0, 'excused': 0};
  }

  /// 요일별 출석 패턴 반환
  Map<String, int> getWeeklyPattern() {
    final pattern = _attendancePattern['weeklyPattern'];
    return pattern != null ? Map<String, int>.from(pattern) : {};
  }

  /// 개선 제안 리스트 반환
  List<String> getImprovementSuggestions() {
    final suggestions = _attendancePattern['improvementSuggestions'];
    return suggestions != null ? List<String>.from(suggestions) : [];
  }

  /// 최근 출석 트렌드 반환
  String getRecentTrend() {
    return _attendancePattern['recentTrend'] ?? '분석 중';
  }

  /// 특정 수업의 출석률 반환
  int getClassAttendanceRate(String classId) {
    final classStats = getClassStatistics();
    final classData = classStats.firstWhere(
      (stats) => stats['classId'] == classId,
      orElse: () => {'attendanceRate': 0},
    );
    return classData['attendanceRate'] ?? 0;
  }

  /// 출석률에 따른 색상 반환
  Color getAttendanceRateColor(int rate) {
    if (rate >= 95) return const Color(0xFF10B981); // 초록색 - 우수
    if (rate >= 90) return const Color(0xFF3B82F6); // 파란색 - 양호
    if (rate >= 80) return const Color(0xFFF59E0B); // 주황색 - 보통
    if (rate >= 70) return const Color(0xFFEF4444); // 빨간색 - 주의
    return const Color(0xFF6B7280); // 회색 - 경고
  }

  /// 상태별 색상 반환
  Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF10B981); // 초록색
      case 'late':
        return const Color(0xFFF59E0B); // 주황색
      case 'absent':
        return const Color(0xFFEF4444); // 빨간색
      case 'excused':
        return const Color(0xFF3B82F6); // 파란색
      default:
        return const Color(0xFF6B7280); // 회색
    }
  }

  /// 상태 한글명 반환
  String getStatusText(String status) {
    switch (status) {
      case 'present':
        return '출석';
      case 'late':
        return '지각';
      case 'absent':
        return '결석';
      case 'excused':
        return '공결';
      default:
        return '미확인';
    }
  }

  /// 학습 목표 달성도 계산
  Map<String, dynamic> getLearningGoalProgress() {
    final attendanceRate = getOverallAttendanceRate();
    final totalSessions = _studentStatistics['totalSessions'] ?? 0;
    const targetRate = 90; // 목표 출석률 90%

    return {
      'currentRate': attendanceRate,
      'targetRate': targetRate,
      'isOnTrack': attendanceRate >= targetRate,
      'sessionsNeeded': _calculateSessionsNeeded(
        attendanceRate,
        totalSessions,
        targetRate,
      ),
      'progressPercentage':
          (attendanceRate / targetRate * 100).clamp(0, 100).round(),
    };
  }

  /// 목표 달성에 필요한 출석 횟수 계산
  int _calculateSessionsNeeded(
    int currentRate,
    int totalSessions,
    int targetRate,
  ) {
    if (currentRate >= targetRate) return 0;

    // 간단한 계산: 현재 출석률을 목표 출석률까지 올리는데 필요한 연속 출석 횟수
    final currentAttended = (totalSessions * currentRate / 100).round();
    int additionalSessions = 0;

    while (true) {
      final newTotal = totalSessions + additionalSessions;
      final newAttended = currentAttended + additionalSessions;
      final newRate = (newAttended / newTotal * 100).round();

      if (newRate >= targetRate) break;
      additionalSessions++;

      if (additionalSessions > 20) break; // 무한 루프 방지
    }

    return additionalSessions;
  }
}
