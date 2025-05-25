import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AttendanceStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 특정 수업의 출석 통계 데이터 조회
  Future<Map<String, dynamic>> getClassAttendanceStatistics(
    String classId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('출석 통계 조회 시작: $classId');

      // 기본 날짜 범위 설정 (지난 1개월)
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month - 1, now.day);
      final end = endDate ?? now;

      // 수업 정보 가져오기
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('수업을 찾을 수 없습니다.');
      }

      final classData = classDoc.data()!;
      final List<dynamic> studentIds = classData['studentIds'] ?? [];

      // 해당 기간의 출석 세션 가져오기
      final sessionsQuery =
          await _firestore
              .collection('sessions')
              .where('classId', isEqualTo: classId)
              .where('isActive', isEqualTo: false) // 종료된 세션만
              .where(
                'startTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
              .orderBy('startTime')
              .get();

      final sessions =
          sessionsQuery.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

      debugPrint('찾은 세션 수: ${sessions.length}');

      // 출석 통계 계산
      Map<String, int> statusCounts = {
        'present': 0,
        'late': 0,
        'absent': 0,
        'excused': 0,
      };

      Map<String, Map<String, int>> attendanceByDate = {};
      List<Map<String, dynamic>> studentStatistics = [];

      // 각 세션별 출석 데이터 집계
      for (final session in sessions) {
        final sessionDate =
            (session['startTime'] as Timestamp)
                .toDate()
                .toIso8601String()
                .split('T')[0];

        if (!attendanceByDate.containsKey(sessionDate)) {
          attendanceByDate[sessionDate] = {
            'present': 0,
            'late': 0,
            'absent': 0,
            'excused': 0,
            'total': studentIds.length,
          };
        }

        // 해당 세션의 출석 기록 가져오기
        final attendanceQuery =
            await _firestore
                .collection('attendances')
                .where('sessionId', isEqualTo: session['id'])
                .get();

        final attendanceRecords = <String, String>{};
        for (final doc in attendanceQuery.docs) {
          final data = doc.data();
          attendanceRecords[data['studentId']] = data['status'] ?? 'absent';
        }

        // 각 학생의 출석 상태 확인
        for (final studentId in studentIds) {
          final status = attendanceRecords[studentId] ?? 'absent';

          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          attendanceByDate[sessionDate]![status] =
              (attendanceByDate[sessionDate]![status] ?? 0) + 1;
        }
      }

      // 학생별 통계 계산
      for (final studentId in studentIds) {
        // 학생 정보 가져오기
        try {
          final userDoc =
              await _firestore.collection('users').doc(studentId).get();
          if (!userDoc.exists) {
            debugPrint('학생 정보를 찾을 수 없음: $studentId');
            continue;
          }

          final userData = userDoc.data()!;
          final studentName = userData['name'] ?? '알 수 없는 학생';

          Map<String, int> studentStats = {
            'present': 0,
            'late': 0,
            'absent': 0,
            'excused': 0,
          };

          // 각 세션에서 해당 학생의 출석 상태 확인
          for (final session in sessions) {
            final attendanceQuery =
                await _firestore
                    .collection('attendances')
                    .where('sessionId', isEqualTo: session['id'])
                    .where('studentId', isEqualTo: studentId)
                    .limit(1)
                    .get();

            if (attendanceQuery.docs.isEmpty) {
              studentStats['absent'] = studentStats['absent']! + 1;
            } else {
              final status =
                  attendanceQuery.docs.first.data()['status'] ?? 'absent';
              studentStats[status] = studentStats[status]! + 1;
            }
          }

          // 출석률 계산
          final totalSessions = sessions.length;
          final attendedSessions =
              studentStats['present']! + studentStats['late']!;
          final attendanceRate =
              totalSessions > 0
                  ? (attendedSessions / totalSessions * 100).round()
                  : 0;

          studentStatistics.add({
            'studentId': studentId,
            'studentName': studentName,
            'present': studentStats['present'],
            'late': studentStats['late'],
            'absent': studentStats['absent'],
            'excused': studentStats['excused'],
            'attendanceRate': attendanceRate,
          });
        } catch (e) {
          debugPrint('학생 정보 조회 실패: $studentId, $e');
          continue;
        }
      }

      // 전체 출석률 계산
      final totalSessions = sessions.length;
      final totalStudents = studentIds.length;
      final totalPossible = totalSessions * totalStudents;
      final totalPresent = statusCounts['present']! + statusCounts['late']!;
      final averageAttendanceRate =
          totalPossible > 0 ? (totalPresent / totalPossible * 100).round() : 0;

      debugPrint('출석 통계 계산 완료: 평균 출석률 $averageAttendanceRate%');

      return {
        'classId': classId,
        'className': classData['name'],
        'totalSessions': totalSessions,
        'totalStudents': totalStudents,
        'averageAttendanceRate': averageAttendanceRate,
        'attendanceByStatus': statusCounts,
        'attendanceByDate': attendanceByDate,
        'studentStatistics': studentStatistics,
      };
    } catch (e) {
      debugPrint('출석 통계 조회 실패: $e');
      throw Exception('출석 통계를 불러오는데 실패했습니다: $e');
    }
  }

  /// 특정 수업의 주차별 출석 데이터 조회
  Future<List<Map<String, dynamic>>> getWeeklyAttendanceData(
    String classId,
    int week,
  ) async {
    try {
      debugPrint('주차별 출석 데이터 조회: $classId, 주차 $week');

      // 수업 정보 가져오기
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('수업을 찾을 수 없습니다.');
      }

      final classData = classDoc.data()!;
      final List<dynamic> studentIds = classData['studentIds'] ?? [];

      // 해당 주차의 세션 찾기 (현재 주차를 기준으로 계산)
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final targetWeekStart = weekStart.add(Duration(days: (week - 1) * 7));
      final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));

      // 세션 컬렉션에서 해당 주차의 세션 찾기
      final sessionsQuery =
          await _firestore
              .collection('sessions')
              .where('classId', isEqualTo: classId)
              .where('isActive', isEqualTo: false) // 종료된 세션만
              .where(
                'startTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(targetWeekStart),
              )
              .where(
                'startTime',
                isLessThanOrEqualTo: Timestamp.fromDate(targetWeekEnd),
              )
              .limit(5) // 한 주에 최대 5개 세션
              .get();

      if (sessionsQuery.docs.isEmpty) {
        debugPrint('해당 주차($week)의 세션이 없습니다.');
        return [];
      }

      // 가장 최근 세션 선택
      QueryDocumentSnapshot<Map<String, dynamic>> latestSession =
          sessionsQuery.docs.first;
      for (final doc in sessionsQuery.docs) {
        final docData = doc.data();
        final latestData = latestSession.data();

        final docTime = (docData['startTime'] as Timestamp?)?.toDate();
        final latestTime = (latestData['startTime'] as Timestamp?)?.toDate();

        if (docTime != null &&
            latestTime != null &&
            docTime.isAfter(latestTime)) {
          latestSession = doc;
        }
      }

      final sessionId = latestSession.id;
      debugPrint('찾은 세션 ID: $sessionId');

      // 해당 세션의 출석 기록 가져오기
      final attendanceQuery =
          await _firestore
              .collection('attendances')
              .where('sessionId', isEqualTo: sessionId)
              .get();

      final attendanceRecords = <String, Map<String, dynamic>>{};
      for (final doc in attendanceQuery.docs) {
        final data = doc.data();
        final studentId = data['studentId'];
        final status = data['status'] ?? 'absent';
        final recordedTime = data['recordedTime'];

        String timeString = '-';
        if (recordedTime != null && recordedTime is Timestamp) {
          final dateTime = recordedTime.toDate();
          timeString =
              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        }

        attendanceRecords[studentId] = {
          'status': status,
          'checkTime': timeString,
        };
      }

      debugPrint('출석 기록 ${attendanceRecords.length}개 찾음');

      // 학생별 출석 데이터 생성
      final List<Map<String, dynamic>> result = [];

      for (final studentId in studentIds) {
        // 학생 정보 가져오기
        try {
          final userDoc =
              await _firestore.collection('users').doc(studentId).get();
          if (!userDoc.exists) {
            debugPrint('학생 정보를 찾을 수 없음: $studentId');
            continue;
          }

          final userData = userDoc.data()!;
          final studentName = userData['name'] ?? '알 수 없는 학생';
          final attendance = attendanceRecords[studentId];

          result.add({
            'id': studentId,
            'name': studentName,
            'studentId': studentId,
            'status': attendance?['status'] ?? 'absent',
            'checkTime': attendance?['checkTime'] ?? '-',
            'week': week,
          });
        } catch (e) {
          debugPrint('학생 정보 조회 실패: $studentId, $e');
          continue;
        }
      }

      debugPrint('주차별 출석 데이터 조회 완료: ${result.length}명');
      return result;
    } catch (e) {
      debugPrint('주차별 출석 데이터 조회 실패: $e');
      return []; // 예외를 던지지 않고 빈 배열 반환
    }
  }

  /// 수업별 출석률 비교 데이터 조회 (교수가 담당하는 모든 수업)
  Future<List<Map<String, dynamic>>> getClassesComparisonData(
    String professorId,
  ) async {
    try {
      debugPrint('수업별 출석률 비교 데이터 조회: $professorId');

      // 교수의 수업 목록 가져오기
      final classesQuery =
          await _firestore
              .collection('classes')
              .where('professorId', isEqualTo: professorId)
              .get();

      final List<Map<String, dynamic>> result = [];

      for (final classDoc in classesQuery.docs) {
        final classData = classDoc.data();
        final classId = classDoc.id;
        final className = classData['name'];

        try {
          // 각 수업의 출석 통계 가져오기
          final stats = await getClassAttendanceStatistics(classId);

          result.add({
            'classId': classId,
            'className': className,
            'rate': '${stats['averageAttendanceRate']}%',
            'status': 'present',
            'color': _getColorForAttendanceRate(stats['averageAttendanceRate']),
          });
        } catch (e) {
          debugPrint('수업 $className의 통계 조회 실패: $e');
          // 실패한 수업은 기본값으로 추가
          result.add({
            'classId': classId,
            'className': className,
            'rate': '0%',
            'status': 'absent',
            'color': 0xFFEF4444,
          });
        }
      }

      debugPrint('수업별 출석률 비교 데이터 조회 완료: ${result.length}개 수업');
      return result;
    } catch (e) {
      debugPrint('수업별 출석률 비교 데이터 조회 실패: $e');
      throw Exception('수업별 비교 데이터를 불러오는데 실패했습니다: $e');
    }
  }

  /// 출석률에 따른 색상 반환
  int _getColorForAttendanceRate(int rate) {
    if (rate >= 90) return 0xFF10B981; // 초록색
    if (rate >= 75) return 0xFF3B82F6; // 파란색
    if (rate >= 60) return 0xFFF59E0B; // 주황색
    return 0xFFEF4444; // 빨간색
  }
}
