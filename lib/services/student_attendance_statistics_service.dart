import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StudentAttendanceStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 특정 학생의 전체 출석 통계 조회
  Future<Map<String, dynamic>> getStudentAttendanceStatistics(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('학생 출석 통계 조회 시작: $studentId');

      // 기본 날짜 범위 설정 (학기 시작부터 현재까지)
      final now = DateTime.now();
      final start =
          startDate ?? DateTime(now.year, now.month - 3, now.day); // 3개월 전부터
      final end = endDate ?? now;

      // 학생이 수강하는 수업 목록 가져오기
      final classesQuery =
          await _firestore
              .collection('classes')
              .where('students', arrayContains: studentId)
              .get();

      final classes =
          classesQuery.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

      debugPrint('수강 중인 수업 수: ${classes.length}');

      if (classes.isEmpty) {
        return {
          'studentId': studentId,
          'totalClasses': 0,
          'totalSessions': 0,
          'attendanceByStatus': {
            'present': 0,
            'late': 0,
            'absent': 0,
            'excused': 0,
          },
          'attendanceRate': 0,
          'classStatistics': [],
          'recentAttendance': [],
          'weeklyPattern': {},
        };
      }

      // 전체 통계 변수 초기화
      Map<String, int> totalStatusCounts = {
        'present': 0,
        'late': 0,
        'absent': 0,
        'excused': 0,
      };

      List<Map<String, dynamic>> classStatistics = [];
      List<Map<String, dynamic>> recentAttendance = [];
      Map<String, int> weeklyPattern = {
        'Monday': 0,
        'Tuesday': 0,
        'Wednesday': 0,
        'Thursday': 0,
        'Friday': 0,
      };

      int totalSessions = 0;

      // 각 수업별 출석 통계 계산
      for (final classInfo in classes) {
        final classId = classInfo['id'];
        final className = classInfo['name'] ?? '알 수 없는 수업';

        // 해당 기간의 출석 세션 가져오기
        final sessionsQuery =
            await _firestore
                .collection('attendance_sessions')
                .where('classId', isEqualTo: classId)
                .where(
                  'startTime',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(start),
                )
                .where(
                  'startTime',
                  isLessThanOrEqualTo: Timestamp.fromDate(end),
                )
                .orderBy('startTime')
                .get();

        final sessions =
            sessionsQuery.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();

        Map<String, int> classStatusCounts = {
          'present': 0,
          'late': 0,
          'absent': 0,
          'excused': 0,
        };

        // 각 세션에서 해당 학생의 출석 기록 확인
        for (final session in sessions) {
          totalSessions++;

          final attendanceQuery =
              await _firestore
                  .collection('attendance_logs')
                  .where('sessionId', isEqualTo: session['id'])
                  .where('studentId', isEqualTo: studentId)
                  .limit(1)
                  .get();

          String status = 'absent'; // 기본값은 결석
          DateTime? attendanceTime;

          if (attendanceQuery.docs.isNotEmpty) {
            final attendanceData = attendanceQuery.docs.first.data();
            status = attendanceData['status'] ?? 'absent';
            attendanceTime =
                attendanceData['timestamp'] != null
                    ? (attendanceData['timestamp'] as Timestamp).toDate()
                    : null;
          }

          // 통계에 반영
          classStatusCounts[status] = classStatusCounts[status]! + 1;
          totalStatusCounts[status] = totalStatusCounts[status]! + 1;

          // 최근 출석 기록 추가 (최근 10개)
          if (recentAttendance.length < 10) {
            recentAttendance.add({
              'className': className,
              'date': (session['startTime'] as Timestamp).toDate(),
              'status': status,
              'attendanceTime': attendanceTime,
            });
          }

          // 요일별 패턴 분석 (출석한 경우만)
          if (status == 'present' || status == 'late') {
            final sessionDate = (session['startTime'] as Timestamp).toDate();
            final weekday = _getWeekdayName(sessionDate.weekday);
            if (weeklyPattern.containsKey(weekday)) {
              weeklyPattern[weekday] = weeklyPattern[weekday]! + 1;
            }
          }
        }

        // 수업별 출석률 계산
        final classTotalSessions = sessions.length;
        final classAttendedSessions =
            classStatusCounts['present']! + classStatusCounts['late']!;
        final classAttendanceRate =
            classTotalSessions > 0
                ? (classAttendedSessions / classTotalSessions * 100).round()
                : 0;

        classStatistics.add({
          'classId': classId,
          'className': className,
          'totalSessions': classTotalSessions,
          'attendanceRate': classAttendanceRate,
          'statusCounts': classStatusCounts,
        });
      }

      // 전체 출석률 계산
      final totalAttendedSessions =
          totalStatusCounts['present']! + totalStatusCounts['late']!;
      final overallAttendanceRate =
          totalSessions > 0
              ? (totalAttendedSessions / totalSessions * 100).round()
              : 0;

      // 최근 출석 기록 날짜순 정렬
      recentAttendance.sort((a, b) => b['date'].compareTo(a['date']));

      debugPrint('학생 출석 통계 계산 완료: 전체 출석률 $overallAttendanceRate%');

      return {
        'studentId': studentId,
        'totalClasses': classes.length,
        'totalSessions': totalSessions,
        'attendanceByStatus': totalStatusCounts,
        'attendanceRate': overallAttendanceRate,
        'classStatistics': classStatistics,
        'recentAttendance': recentAttendance,
        'weeklyPattern': weeklyPattern,
      };
    } catch (e) {
      debugPrint('학생 출석 통계 조회 실패: $e');
      throw Exception('출석 통계를 불러오는데 실패했습니다: $e');
    }
  }

  /// 특정 수업에서 학생의 상세 출석 기록 조회
  Future<List<Map<String, dynamic>>> getStudentClassAttendanceHistory(
    String studentId,
    String classId, {
    int limit = 20,
  }) async {
    try {
      debugPrint('학생 수업별 출석 기록 조회: $studentId, $classId');

      // 해당 수업의 출석 세션 가져오기
      final sessionsQuery =
          await _firestore
              .collection('attendance_sessions')
              .where('classId', isEqualTo: classId)
              .orderBy('startTime', descending: true)
              .limit(limit)
              .get();

      final List<Map<String, dynamic>> attendanceHistory = [];

      for (final sessionDoc in sessionsQuery.docs) {
        final sessionData = sessionDoc.data();
        final sessionId = sessionDoc.id;

        // 해당 세션에서 학생의 출석 기록 조회
        final attendanceQuery =
            await _firestore
                .collection('attendance_logs')
                .where('sessionId', isEqualTo: sessionId)
                .where('studentId', isEqualTo: studentId)
                .limit(1)
                .get();

        String status = 'absent';
        DateTime? attendanceTime;

        if (attendanceQuery.docs.isNotEmpty) {
          final attendanceData = attendanceQuery.docs.first.data();
          status = attendanceData['status'] ?? 'absent';
          attendanceTime =
              attendanceData['timestamp'] != null
                  ? (attendanceData['timestamp'] as Timestamp).toDate()
                  : null;
        }

        attendanceHistory.add({
          'sessionId': sessionId,
          'date': (sessionData['startTime'] as Timestamp).toDate(),
          'status': status,
          'attendanceTime': attendanceTime,
          'sessionDuration': sessionData['duration'] ?? 0,
        });
      }

      debugPrint('학생 수업별 출석 기록 조회 완료: ${attendanceHistory.length}개');
      return attendanceHistory;
    } catch (e) {
      debugPrint('학생 수업별 출석 기록 조회 실패: $e');
      throw Exception('출석 기록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 학생의 출석 패턴 분석
  Future<Map<String, dynamic>> getStudentAttendancePattern(
    String studentId,
  ) async {
    try {
      debugPrint('학생 출석 패턴 분석 시작: $studentId');

      final statisticsData = await getStudentAttendanceStatistics(studentId);

      // 출석률에 따른 등급 계산
      final attendanceRate = statisticsData['attendanceRate'] as int;
      String gradeLevel;
      String recommendation;

      if (attendanceRate >= 95) {
        gradeLevel = '우수';
        recommendation = '매우 우수한 출석률을 유지하고 있습니다!';
      } else if (attendanceRate >= 90) {
        gradeLevel = '양호';
        recommendation = '좋은 출석률입니다. 지속적으로 유지해주세요.';
      } else if (attendanceRate >= 80) {
        gradeLevel = '보통';
        recommendation = '출석률 개선이 필요합니다. 수업 참여를 늘려보세요.';
      } else if (attendanceRate >= 70) {
        gradeLevel = '주의';
        recommendation = '출석률이 낮습니다. 학업에 더 집중하시기 바랍니다.';
      } else {
        gradeLevel = '경고';
        recommendation = '출석률이 매우 낮습니다. 즉시 개선이 필요합니다.';
      }

      // 최근 출석 트렌드 분석
      final recentAttendance =
          statisticsData['recentAttendance'] as List<Map<String, dynamic>>;
      final recentTrend = _analyzeRecentTrend(recentAttendance);

      return {
        'attendanceRate': attendanceRate,
        'gradeLevel': gradeLevel,
        'recommendation': recommendation,
        'recentTrend': recentTrend,
        'weeklyPattern': statisticsData['weeklyPattern'],
        'improvementSuggestions': _getImprovementSuggestions(
          attendanceRate,
          recentTrend,
        ),
      };
    } catch (e) {
      debugPrint('학생 출석 패턴 분석 실패: $e');
      throw Exception('출석 패턴 분석에 실패했습니다: $e');
    }
  }

  /// 요일 이름 변환
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      default:
        return 'Other';
    }
  }

  /// 최근 출석 트렌드 분석
  String _analyzeRecentTrend(List<Map<String, dynamic>> recentAttendance) {
    if (recentAttendance.length < 3) return '데이터 부족';

    final recent5 = recentAttendance.take(5).toList();
    int presentCount = 0;

    for (final record in recent5) {
      if (record['status'] == 'present' || record['status'] == 'late') {
        presentCount++;
      }
    }

    final recentRate = presentCount / recent5.length;

    if (recentRate >= 0.8) return '상승';
    if (recentRate >= 0.6) return '안정';
    return '하락';
  }

  /// 개선 제안 생성
  List<String> _getImprovementSuggestions(int attendanceRate, String trend) {
    List<String> suggestions = [];

    if (attendanceRate < 80) {
      suggestions.add('수업 시작 10분 전 알림을 설정해보세요');
      suggestions.add('일정 관리 앱을 활용하여 수업 시간을 체계적으로 관리해보세요');
    }

    if (trend == '하락') {
      suggestions.add('최근 출석률이 하락하고 있습니다. 수업 참여 의지를 점검해보세요');
    }

    if (attendanceRate >= 90) {
      suggestions.add('우수한 출석률을 유지하고 있습니다. 현재 습관을 계속 유지하세요');
    }

    if (suggestions.isEmpty) {
      suggestions.add('꾸준한 출석으로 학업 성취도를 높여보세요');
    }

    return suggestions;
  }
}
