import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/attendance_statistics_service.dart';
import '../../core/dependency_injection.dart' as di;
import 'package:cloud_firestore/cloud_firestore.dart';

/// 교수용 출석 데이터를 관리하는 Provider 클래스
class ProfessorAttendanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, Map<String, dynamic>> _attendanceStats = {};
  late final AttendanceStatisticsService _statisticsService;
  bool _isInitialized = false;
  String? _currentProfessorId;

  // 캐싱 시스템 - 더 공격적인 캐싱
  Map<String, Map<String, dynamic>> _cachedAttendanceStats = {};
  final Map<String, List<Map<String, dynamic>>> _weeklyDataCache = {};
  final Map<String, Map<String, List<Map<String, dynamic>>>>
  _allWeeksDataCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5); // 5분 캐시 유효시간
  static const Duration _sessionCacheExpiry = Duration(hours: 1); // 세션 캐시 1시간

  // 스마트 로딩 상태
  bool _isBackgroundLoading = false;
  final Map<String, bool> _classDataLoaded = {};

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, Map<String, dynamic>> get attendanceStats => _attendanceStats;
  bool get isInitialized => _isInitialized;

  /// 생성자
  ProfessorAttendanceProvider() {
    try {
      _statisticsService = di.sl<AttendanceStatisticsService>();
    } catch (e) {
      debugPrint('AttendanceStatisticsService 초기화 실패: $e');
      // 서비스가 없을 경우 새로 생성 (임시)
      _statisticsService = AttendanceStatisticsService();
    }

    // 기본 더미 데이터로 초기화
    _initializeDummyData();
    // 생성자에서는 더미 데이터만 로드, 실제 데이터는 initializeWithProfessorId 호출 시 로드
  }

  /// 교수 ID로 초기화 및 실제 데이터 로드
  Future<void> initializeWithProfessorId(String professorId) async {
    // 이미 같은 교수 ID로 초기화되었다면 스킵
    if (_isInitialized && _currentProfessorId == professorId) {
      debugPrint('교수 ID $professorId로 이미 초기화됨, 스킵');
      return;
    }

    debugPrint('교수 ID로 Provider 초기화: $professorId');
    _currentProfessorId = professorId;
    await _fetchAttendanceStats(professorId);
    _isInitialized = true;
  }

  /// 더미 데이터 초기화
  void _initializeDummyData() {
    _attendanceStats = {
      'capstone': {
        'classId': 'cap_design_2023',
        'className': '캡스톤 디자인',
        'rate': '95%',
        'totalStudents': 20,
        'presentStudents': 19,
        'color': const Color(0xFF10B981),
      },
      'database': {
        'classId': 'database_2023',
        'className': '데이터베이스',
        'rate': '88%',
        'totalStudents': 25,
        'presentStudents': 22,
        'color': const Color(0xFF3B82F6),
      },
    };
  }

  /// 캐시된 데이터가 유효한지 확인
  bool _isCacheValid(String professorId) {
    if (_lastCacheUpdate == null || _cachedAttendanceStats.isEmpty)
      return false;
    if (_currentProfessorId != professorId) return false;

    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!) < _cacheExpiry;
  }

  /// 출석 통계 데이터 조회 (특정 교수의 모든 수업)
  Future<void> _fetchAttendanceStats([String? professorId]) async {
    // 캐시된 데이터가 유효하면 사용
    if (professorId != null && _isCacheValid(professorId)) {
      debugPrint('캐시된 데이터 사용: $professorId');
      _attendanceStats = Map.from(_cachedAttendanceStats);
      _errorMessage = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (professorId == null) {
        debugPrint('교수 ID가 없어 더미 데이터를 사용합니다.');
        _initializeDummyData();
        _errorMessage = '';
      } else {
        debugPrint('실제 Firebase 데이터 조회 시작: $professorId');
        final stopwatch = Stopwatch()..start();

        // 실제 데이터 가져오기 - 병렬 처리로 최적화
        final comparisonData = await _statisticsService
            .getClassesComparisonData(professorId);

        debugPrint('Firebase에서 가져온 수업 수: ${comparisonData.length}');

        if (comparisonData.isEmpty) {
          debugPrint('Firebase에서 수업 데이터를 찾을 수 없어 더미 데이터 사용');
          _initializeDummyData();
          _errorMessage = '등록된 수업이 없어 샘플 데이터를 표시합니다.';
          return;
        }

        // 모든 수업의 상세 통계를 병렬로 가져오기
        final List<Future<Map<String, dynamic>?>> futures =
            comparisonData.map((classData) async {
              try {
                final classStats = await _statisticsService
                    .getClassAttendanceStatistics(classData['classId']);
                return {...classData, 'detailedStats': classStats};
              } catch (e) {
                debugPrint('수업 ${classData['className']}의 상세 통계 조회 실패: $e');
                return {
                  ...classData,
                  'detailedStats': {'totalStudents': 20}, // 기본값
                };
              }
            }).toList();

        // 모든 요청을 병렬로 처리
        final results = await Future.wait(futures);

        _attendanceStats = {};
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          if (result == null) continue;

          final key = 'class_$i';
          final classData = result;
          final detailedStats = result['detailedStats'] as Map<String, dynamic>;

          // 출석률에서 '%' 제거하고 숫자만 추출
          final rateString = classData['rate'] as String;
          final rateValue = int.tryParse(rateString.replaceAll('%', '')) ?? 0;

          final totalStudents = detailedStats['totalStudents'] ?? 20;
          final presentStudents = (totalStudents * rateValue / 100).round();

          _attendanceStats[key] = {
            'classId': classData['classId'],
            'className': classData['className'],
            'rate': classData['rate'],
            'totalStudents': totalStudents,
            'presentStudents': presentStudents,
            'color': Color(classData['color'] as int),
          };

          debugPrint(
            '수업 추가: ${classData['className']} - 출석률: ${classData['rate']}',
          );
        }

        if (_attendanceStats.isEmpty) {
          debugPrint('Firebase에서 수업 데이터를 찾을 수 없어 더미 데이터 사용');
          _initializeDummyData();
          _errorMessage = '등록된 수업이 없어 샘플 데이터를 표시합니다.';
        } else {
          // 캐시에 저장
          _cachedAttendanceStats = Map.from(_attendanceStats);
          _lastCacheUpdate = DateTime.now();
          _errorMessage = '';

          stopwatch.stop();
          debugPrint(
            '데이터 로드 완료: ${_attendanceStats.length}개 수업, 소요시간: ${stopwatch.elapsedMilliseconds}ms',
          );
        }
      }
    } catch (e) {
      debugPrint('출석 통계 조회 실패: $e');
      _errorMessage = '출석 데이터를 불러오는데 실패했습니다: $e';

      // 오류 발생 시 더미 데이터로 초기화 (빈 맵이 아닌)
      _initializeDummyData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 출석 통계 데이터 새로고침 (강제 갱신)
  Future<void> refreshAttendanceStats([String? professorId]) async {
    // 캐시 무효화
    _lastCacheUpdate = null;
    _cachedAttendanceStats.clear();
    await _fetchAttendanceStats(professorId);
  }

  /// 백그라운드에서 데이터 미리 로드 (Preloading)
  Future<void> preloadAttendanceStats(String professorId) async {
    if (_isCacheValid(professorId)) return; // 이미 유효한 캐시가 있으면 스킵

    try {
      debugPrint('백그라운드에서 출석 통계 미리 로드: $professorId');
      await _fetchAttendanceStats(professorId);
    } catch (e) {
      debugPrint('백그라운드 데이터 로드 실패: $e');
    }
  }

  /// 특정 수업의 출석 통계 데이터 조회
  Map<String, dynamic>? getClassAttendanceStats(String classId) {
    return _attendanceStats.values.firstWhere(
      (stats) => stats['classId'] == classId,
      orElse: () => <String, dynamic>{},
    );
  }

  /// 모든 수업 통계 데이터 조회
  Map<String, Map<String, dynamic>> getAttendanceStats() {
    return _attendanceStats;
  }

  /// 특정 수업의 주차별 출석률 데이터 생성 (차트용 더미 데이터)
  List<Map<String, dynamic>> getWeeklyAttendanceRateByClass(String classId) {
    // 임시 데이터 생성 (실제로는 데이터베이스에서 가져온 데이터 사용)
    final List<Map<String, dynamic>> result = [];

    // 수업 정보 확인
    Map<String, dynamic>? classInfo;
    try {
      classInfo = getClassAttendanceStats(classId);
    } catch (e) {
      return [];
    }

    if (classInfo == null || classInfo.isEmpty) {
      return [];
    }

    // 14주차 데이터 생성
    for (int i = 1; i <= 14; i++) {
      // 간단한 패턴의 임시 데이터
      double baseRate = classId == 'cap_design_2023' ? 95 : 88;
      double fluctuation = (i % 3 - 1) * 5.0; // -5, 0, 5 사이 값
      double weekRate = baseRate + fluctuation;

      // 특정 주차에 결석/지각 패턴 추가
      String status = 'present';
      if (classId == 'cap_design_2023') {
        if (i == 4) status = 'late'; // 4주차는 지각 많음
        if (i == 9) status = 'absent'; // 9주차는 결석 많음
      } else {
        if (i == 3) status = 'late'; // 3주차는 지각 많음
        if (i == 7) status = 'absent'; // 7주차는 결석 많음
      }

      // 미래 주차는 예측 데이터로 표시
      if (i > 12) {
        status = 'future';
        weekRate = baseRate;
      }

      // 출석 상태에 따라 값 조정
      if (status == 'late') weekRate -= 10;
      if (status == 'absent') weekRate -= 20;

      // 값 범위 제한
      weekRate = weekRate.clamp(0, 100);

      result.add({
        'week': i.toString(),
        'status': status,
        'rate': '${weekRate.toStringAsFixed(1)}%',
        'date': '2023-03-${i < 10 ? '0$i' : i}',
        'className': classInfo['className'],
      });
    }

    return result;
  }

  /// 특정 수업의 출석 상태별 학생 수 조회 (차트용 더미 데이터)
  Map<String, int> getAttendanceStatusCountByClass(String classId) {
    Map<String, dynamic>? classInfo;
    try {
      classInfo = getClassAttendanceStats(classId);
    } catch (e) {
      return {'present': 0, 'late': 0, 'absent': 0, 'total': 0};
    }

    if (classInfo == null || classInfo.isEmpty) {
      return {'present': 0, 'late': 0, 'absent': 0, 'total': 0};
    }

    final totalStudents = classInfo['totalStudents'] as int;
    final presentStudents = classInfo['presentStudents'] as int;
    final lateStudents = (totalStudents * 0.1).round(); // 10%는 지각
    final absentStudents = totalStudents - presentStudents - lateStudents;

    return {
      'present': presentStudents,
      'late': lateStudents,
      'absent': absentStudents,
      'total': totalStudents,
    };
  }

  /// 수업별 출석률 비교 데이터 (차트용)
  List<Map<String, dynamic>> getClassesComparisonData() {
    // 모든 수업의 출석률 데이터 변환
    return _attendanceStats.values.map((classData) {
      return {
        'className': classData['className'],
        'rate': classData['rate'],
        'status': 'present', // 단순화를 위해 모두 present 상태로 표시
        'color': classData['color'],
      };
    }).toList();
  }

  /// 특정 수업의 주차별 학생 출석 현황 데이터 조회
  List<Map<String, dynamic>> getWeeklyStudentAttendanceByClass(
    String classId,
    int week,
  ) {
    // 임시 데이터 (실제로는 데이터베이스에서 가져온 데이터 사용)
    final List<Map<String, dynamic>> students = [
      {'id': '20201234', 'name': '김학생', 'major': '컴퓨터공학과'},
      {'id': '20201235', 'name': '이학생', 'major': '컴퓨터공학과'},
      {'id': '20201236', 'name': '박학생', 'major': '정보통신공학과'},
      {'id': '20201237', 'name': '최학생', 'major': '정보통신공학과'},
      {'id': '20201238', 'name': '정학생', 'major': '컴퓨터공학과'},
      {'id': '20201239', 'name': '한학생', 'major': '소프트웨어공학과'},
      {'id': '20201240', 'name': '윤학생', 'major': '소프트웨어공학과'},
      {'id': '20201241', 'name': '오학생', 'major': '컴퓨터공학과'},
    ];

    final List<Map<String, dynamic>> result = [];
    final random =
        DateTime(2023, 3, week).millisecondsSinceEpoch; // 주차마다 다른 패턴 생성

    for (var student in students) {
      // 출석 상태 결정 (실제로는 데이터베이스에서 가져와야 함)
      String status;
      String time;

      // 학생 ID와 주차를 기반으로 일관된 출석 상태 생성
      int hash = int.parse(student['id'].substring(5)) + week;
      int mod = hash % 10;

      if (mod < 7) {
        // 70% 출석
        status = 'present';
        time = '09:${(hash % 10) + (week % 10)}';
      } else if (mod < 9) {
        // 20% 지각
        status = 'late';
        time = '09:${15 + (hash % 10)}';
      } else {
        // 10% 결석
        status = 'absent';
        time = '-';
      }

      result.add({...student, 'status': status, 'time': time, 'week': week});
    }

    return result;
  }

  /// 학생 출석 현황을 전체 주차별로 조회 (출석 현황 테이블용)
  Map<String, List<Map<String, dynamic>>> getAllWeeksStudentAttendance(
    String classId, {
    int totalWeeks = 14,
  }) {
    Map<String, List<Map<String, dynamic>>> result = {};

    // 각 주차별 데이터 생성
    for (int week = 1; week <= totalWeeks; week++) {
      String weekKey = week.toString();
      result[weekKey] = getWeeklyStudentAttendanceByClass(classId, week);
    }

    return result;
  }

  /// 특정 수업의 주차별 학생 출석 데이터를 가져오는 메서드
  Future<List<Map<String, dynamic>>> getAttendanceByWeek(
    String classId,
    int week,
  ) async {
    // 로딩 상태 설정
    _isLoading = true;
    notifyListeners();

    try {
      // 실제 Firebase 데이터 가져오기
      final attendanceData = await _statisticsService.getWeeklyAttendanceData(
        classId,
        week,
      );

      if (attendanceData.isNotEmpty) {
        _errorMessage = '';
        return attendanceData;
      } else {
        // Firebase에서 데이터를 찾을 수 없으면 하드코딩된 데이터 사용 (개발용)
        debugPrint('Firebase에서 데이터를 찾을 수 없어 하드코딩된 데이터 사용: $classId, 주차 $week');
        final fallbackData = getWeeklyStudentAttendanceByClass(classId, week);

        final formattedData =
            fallbackData.map((student) {
              return {
                'id': student['id'],
                'name': student['name'],
                'studentId': student['id'],
                'status': student['status'],
                'checkTime': student['time'],
              };
            }).toList();

        _errorMessage = '';
        return formattedData;
      }
    } catch (e) {
      debugPrint('출석 데이터 조회 실패, 하드코딩된 데이터 사용: $e');

      // 오류 발생 시 하드코딩된 데이터로 폴백
      try {
        final fallbackData = getWeeklyStudentAttendanceByClass(classId, week);
        final formattedData =
            fallbackData.map((student) {
              return {
                'id': student['id'],
                'name': student['name'],
                'studentId': student['id'],
                'status': student['status'],
                'checkTime': student['time'],
              };
            }).toList();

        _errorMessage = '실제 데이터를 불러올 수 없어 임시 데이터를 표시합니다.';
        return formattedData;
      } catch (fallbackError) {
        _errorMessage = '출석 데이터를 불러오는데 실패했습니다: $fallbackError';
        return [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 스마트 데이터 로딩 - 즉시 캐시 반환 후 백그라운드 업데이트
  Future<void> smartFetchAttendanceStats(String professorId) async {
    // 1단계: 캐시된 데이터가 있으면 즉시 반환
    if (_isCacheValid(professorId)) {
      debugPrint('캐시된 데이터 즉시 반환: $professorId');
      _attendanceStats = Map.from(_cachedAttendanceStats);
      _errorMessage = '';
      notifyListeners();

      // 백그라운드에서 업데이트 확인
      _updateInBackground(professorId);
      return;
    }

    // 2단계: 캐시가 없으면 더미 데이터 먼저 표시
    if (_attendanceStats.isEmpty) {
      _initializeDummyData();
      notifyListeners();
    }

    // 3단계: 실제 데이터 로드
    await _fetchAttendanceStats(professorId);
  }

  /// 백그라운드에서 데이터 업데이트
  void _updateInBackground(String professorId) async {
    if (_isBackgroundLoading) return;

    _isBackgroundLoading = true;
    try {
      debugPrint('백그라운드에서 데이터 업데이트 시작');

      // 조용히 데이터 가져오기 (UI 로딩 표시 없음)
      final oldIsLoading = _isLoading;
      await _fetchAttendanceStats(professorId);
      _isLoading = oldIsLoading; // 로딩 상태 복원

      debugPrint('백그라운드 업데이트 완료');
    } catch (e) {
      debugPrint('백그라운드 업데이트 실패: $e');
    } finally {
      _isBackgroundLoading = false;
    }
  }

  /// 데이터 청킹 - 필요한 데이터만 우선 로드
  Future<void> loadEssentialDataOnly(String professorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('필수 데이터만 우선 로드: $professorId');

      // 기본 수업 목록만 빠르게 가져오기
      final basicClasses = await _statisticsService.getClassesComparisonData(
        professorId,
      );

      // 기본 정보로 _attendanceStats 구성
      _attendanceStats = {};
      for (int i = 0; i < basicClasses.length; i++) {
        final classData = basicClasses[i];
        _attendanceStats['class_$i'] = {
          'classId': classData['classId'],
          'className': classData['className'],
          'rate': '로딩중...',
          'totalStudents': 0,
          'presentStudents': 0,
          'color': const Color(0xFF3B82F6),
        };
      }

      _errorMessage = '';
      notifyListeners();

      // 백그라운드에서 상세 데이터 로드
      _loadDetailedDataInBackground(professorId);
    } catch (e) {
      debugPrint('필수 데이터 로드 실패: $e');
      _initializeDummyData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 백그라운드에서 상세 데이터 로드
  void _loadDetailedDataInBackground(String professorId) async {
    try {
      debugPrint('백그라운드에서 상세 데이터 로드 시작');

      // 각 수업의 상세 통계를 순차적으로 로드하여 UI 점진적 업데이트
      final classes = _attendanceStats.keys.toList();

      for (final classKey in classes) {
        final classData = _attendanceStats[classKey];
        if (classData == null) continue;

        try {
          final stats = await _statisticsService.getClassAttendanceStatistics(
            classData['classId'],
          );

          // 개별 수업 데이터 업데이트
          _attendanceStats[classKey] = {
            ...classData,
            'rate': '${(stats['attendanceRate'] ?? 95).toStringAsFixed(1)}%',
            'totalStudents': stats['totalStudents'] ?? 20,
            'presentStudents': stats['presentStudents'] ?? 19,
          };

          // 즉시 UI 업데이트
          notifyListeners();

          // 부드러운 로딩을 위한 짧은 지연
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('${classData['className']} 상세 데이터 로드 실패: $e');
        }
      }

      // 캐시 업데이트
      _cachedAttendanceStats = Map.from(_attendanceStats);
      _lastCacheUpdate = DateTime.now();

      debugPrint('백그라운드 상세 데이터 로드 완료');
    } catch (e) {
      debugPrint('백그라운드 상세 데이터 로드 실패: $e');
    }
  }

  /// 홈 화면용 경량 수업 목록 로딩 (상세 통계 제외)
  Future<void> loadBasicClassList(String professorId) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🚀 교수용 기본 수업 목록 로딩 시작: $professorId');

      // 같은 교수 ID로 이미 로딩된 상태라면 완전히 스킵
      if (_currentProfessorId == professorId && _attendanceStats.isNotEmpty) {
        debugPrint('✅ 이미 로딩된 상태, 스킵 (${stopwatch.elapsedMilliseconds}ms)');
        return;
      }

      // 현재 로딩 중이라면 스킵
      if (_isLoading) {
        debugPrint('⏳ 이미 로딩 중, 스킵');
        return;
      }

      _currentProfessorId = professorId;
      _isLoading = true;
      notifyListeners();

      // 교수의 수업 목록을 직접 Firebase에서 가져오기
      final classesQuery =
          await FirebaseFirestore.instance
              .collection('classes')
              .where('professorId', isEqualTo: professorId)
              .get();

      debugPrint('📊 수업 목록 조회 완료: ${classesQuery.docs.length}개');

      if (classesQuery.docs.isEmpty) {
        debugPrint('⚠️ 등록된 수업이 없음, 더미 데이터 사용');
        _initializeDummyData();
        _errorMessage = '등록된 수업이 없어 샘플 데이터를 표시합니다.';
      } else {
        // 실제 수업 데이터로 _attendanceStats 구성
        _attendanceStats = {};
        final colors = [
          const Color(0xFF10B981), // 그린
          const Color(0xFF3B82F6), // 블루
          const Color(0xFFF59E0B), // 옐로우
          const Color(0xFFEF4444), // 레드
          const Color(0xFF8B5CF6), // 퍼플
          const Color(0xFF06B6D4), // 시안
          const Color(0xFFEC4899), // 핑크
        ];

        for (int i = 0; i < classesQuery.docs.length; i++) {
          final classDoc = classesQuery.docs[i];
          final classData = classDoc.data();
          final classId = classDoc.id;
          final className = classData['name'] ?? '알 수 없는 수업';
          final studentIds = List<String>.from(classData['studentIds'] ?? []);
          final key = 'class_$i';

          // 간단한 출석률 계산 (기본적으로 랜덤하게 설정하되, 실제 데이터가 있으면 사용)
          double attendanceRate = 85.0 + (i * 5.0); // 기본 출석률

          // 실제 출석 데이터가 있는지 확인
          try {
            final sessionsQuery =
                await FirebaseFirestore.instance
                    .collection('sessions')
                    .where('classId', isEqualTo: classId)
                    .where('isActive', isEqualTo: false)
                    .limit(10)
                    .get();

            if (sessionsQuery.docs.isNotEmpty) {
              // 실제 출석률 계산
              int totalAttendances = 0;
              int totalPossible = 0;

              for (final sessionDoc in sessionsQuery.docs) {
                final attendanceQuery =
                    await FirebaseFirestore.instance
                        .collection('attendances')
                        .where('sessionId', isEqualTo: sessionDoc.id)
                        .get();

                final presentCount =
                    attendanceQuery.docs
                        .where(
                          (doc) =>
                              doc.data()['status'] == 'present' ||
                              doc.data()['status'] == 'late',
                        )
                        .length;

                totalAttendances += presentCount;
                totalPossible += studentIds.length;
              }

              if (totalPossible > 0) {
                attendanceRate = (totalAttendances / totalPossible * 100);
              }
            }
          } catch (e) {
            debugPrint('출석률 계산 실패 ($className): $e');
            // 기본값 유지
          }

          _attendanceStats[key] = {
            'classId': classId,
            'className': className,
            'rate': '${attendanceRate.toStringAsFixed(1)}%',
            'totalStudents': studentIds.length,
            'presentStudents':
                (studentIds.length * attendanceRate / 100).round(),
            'color': colors[i % colors.length],
            'isBasicOnly': false, // 실제 데이터 로드 완료
          };

          debugPrint(
            '✅ 수업 추가: $className (출석률: ${attendanceRate.toStringAsFixed(1)}%, 학생수: ${studentIds.length})',
          );
        }

        _errorMessage = '';
        debugPrint('✅ 실제 수업 목록 로딩 완료: ${_attendanceStats.length}개');
      }
    } catch (e) {
      debugPrint('❌ 수업 목록 로딩 실패: $e');
      _errorMessage = '수업 목록을 불러오는데 실패했습니다: $e';
      _initializeDummyData();
    } finally {
      _isLoading = false;
      notifyListeners();
      stopwatch.stop();
      debugPrint('🏁 수업 목록 로딩 총 소요시간: ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  /// 특정 수업의 상세 통계를 필요할 때 로드
  Future<void> loadClassDetailStats(String classId) async {
    try {
      debugPrint('수업 상세 통계 로딩 시작: $classId');

      // 해당 수업 찾기
      String? classKey;
      for (final entry in _attendanceStats.entries) {
        if (entry.value['classId'] == classId) {
          classKey = entry.key;
          break;
        }
      }

      if (classKey == null) {
        debugPrint('수업을 찾을 수 없음: $classId');
        return;
      }

      // 이미 상세 통계가 로드된 경우 완전히 스킵
      final classData = _attendanceStats[classKey]!;
      if (classData['isBasicOnly'] != true) {
        debugPrint('이미 상세 통계가 로드됨: $classId');
        return;
      }

      // 로딩 중 표시로 중복 호출 방지
      _attendanceStats[classKey] = {
        ...classData,
        'isBasicOnly': false, // 로딩 중 상태로 변경
      };
      notifyListeners();

      // 상세 통계 로드
      final detailedStats = await _statisticsService
          .getClassAttendanceStatistics(classId);

      // 출석률 계산
      final totalStudents = detailedStats['totalStudents'] ?? 20;
      final attendanceRate = detailedStats['attendanceRate'] ?? 95.0;
      final presentStudents = (totalStudents * attendanceRate / 100).round();

      // 상세 정보로 업데이트
      _attendanceStats[classKey] = {
        ...classData,
        'rate': '${attendanceRate.toStringAsFixed(1)}%',
        'totalStudents': totalStudents,
        'presentStudents': presentStudents,
        'isBasicOnly': false, // 상세 통계 로드 완료
      };

      notifyListeners();
      debugPrint(
        '수업 상세 통계 로딩 완료: $classId - ${attendanceRate.toStringAsFixed(1)}%',
      );
    } catch (e) {
      debugPrint('수업 상세 통계 로딩 실패 ($classId): $e');
    }
  }
}
