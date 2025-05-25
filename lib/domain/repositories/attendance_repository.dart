import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../entities/attendance.dart';
import '../entities/attendance_entity.dart' as entity;
import '../entities/session_entity.dart';
import '../entities/activity_log.dart';
import '../../core/error/failures.dart';
import '../models/attendance_model.dart' as model;

/// 출석 관리를 위한 Repository 인터페이스
abstract class AttendanceRepository {
  /// 특정 강의의 모든 출석 기록을 가져옵니다.
  Future<Either<Failure, List<model.AttendanceModel>>> getAttendancesByClassId(
    String classId,
  );

  /// 특정 날짜의 출석 기록을 가져옵니다.
  Future<Either<Failure, List<model.AttendanceModel>>> getAttendancesByDate(
    String classId,
    DateTime date,
  );

  /// 특정 학생의 모든 출석 기록을 가져옵니다.
  Future<Either<Failure, List<model.AttendanceModel>>>
  getAttendancesByStudentId(String studentId);

  /// 학생의 특정 강의 출석 기록을 가져옵니다.
  Future<Either<Failure, List<model.AttendanceModel>>>
  getStudentAttendancesForClass(String classId, String studentId);

  /// 출석 기록을 생성합니다.
  Future<Either<Failure, String>> createAttendance(
    model.AttendanceModel attendance,
  );

  /// 출석 상태를 업데이트합니다.
  Future<Either<Failure, void>> updateAttendanceStatus(
    String attendanceId,
    model.AttendanceStatus status,
  );

  /// 출석 체크아웃 시간을 업데이트합니다.
  Future<Either<Failure, void>> updateCheckOutTime(
    String attendanceId,
    DateTime checkOutTime,
  );

  /// 출석 기록을 삭제합니다.
  Future<Either<Failure, void>> deleteAttendance(String attendanceId);

  /// 특정 강의의 모든 출석 기록을 삭제합니다.
  Future<Either<Failure, void>> deleteAttendancesByClassId(String classId);

  Future<Either<Failure, List<SessionEntity>>> getClassSessions(String classId);
  Future<Either<Failure, SessionEntity>> getActiveSession(String classId);
  Future<Either<Failure, String>> createSession(SessionEntity sessionEntity);
  Future<Either<Failure, void>> endSession(String sessionId);
  Future<Either<Failure, List<entity.AttendanceEntity>>> getSessionAttendance(
    String sessionId,
  );
  Future<Either<Failure, List<ActivityLog>>> getStudentActivityLogs(
    String sessionId,
    String studentId,
  );
  Stream<List<entity.AttendanceEntity>> watchSessionAttendance(
    String sessionId,
  );
  Stream<List<ActivityLog>> watchStudentActivity(
    String sessionId,
    String studentId,
  );
}

/// 출석 관리 Repository 구현체
class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'attendances';

  AttendanceRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<model.AttendanceModel>>> getAttendancesByClassId(
    String classId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('classId', isEqualTo: classId)
              .orderBy('date', descending: true)
              .get();

      final attendances =
          snapshot.docs
              .map((doc) => model.AttendanceModel.fromFirestore(doc))
              .toList();

      return Right(attendances);
    } catch (e) {
      debugPrint('강의 출석 기록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<model.AttendanceModel>>> getAttendancesByDate(
    String classId,
    DateTime date,
  ) async {
    try {
      // 해당 날짜의 시작과 끝 계산
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('classId', isEqualTo: classId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .get();

      final attendances =
          snapshot.docs
              .map((doc) => model.AttendanceModel.fromFirestore(doc))
              .toList();

      return Right(attendances);
    } catch (e) {
      debugPrint('날짜별 출석 기록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<model.AttendanceModel>>>
  getAttendancesByStudentId(String studentId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('studentId', isEqualTo: studentId)
              .orderBy('date', descending: true)
              .get();

      final attendances =
          snapshot.docs
              .map((doc) => model.AttendanceModel.fromFirestore(doc))
              .toList();

      return Right(attendances);
    } catch (e) {
      debugPrint('학생 출석 기록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<model.AttendanceModel>>>
  getStudentAttendancesForClass(String classId, String studentId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('classId', isEqualTo: classId)
              .where('studentId', isEqualTo: studentId)
              .orderBy('date', descending: true)
              .get();

      final attendances =
          snapshot.docs
              .map((doc) => model.AttendanceModel.fromFirestore(doc))
              .toList();

      return Right(attendances);
    } catch (e) {
      debugPrint('학생의 특정 강의 출석 기록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createAttendance(
    model.AttendanceModel attendance,
  ) async {
    try {
      final docRef = await _firestore
          .collection(_collectionPath)
          .add(attendance.toFirestore());
      return Right(docRef.id);
    } catch (e) {
      debugPrint('출석 기록 생성 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAttendanceStatus(
    String attendanceId,
    model.AttendanceStatus status,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(attendanceId).update({
        'status': status.toString().split('.').last,
      });
      return const Right(null);
    } catch (e) {
      debugPrint('출석 상태 업데이트 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCheckOutTime(
    String attendanceId,
    DateTime checkOutTime,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(attendanceId).update({
        'checkOutTime': Timestamp.fromDate(checkOutTime),
      });
      return const Right(null);
    } catch (e) {
      debugPrint('체크아웃 시간 업데이트 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttendance(String attendanceId) async {
    try {
      await _firestore.collection(_collectionPath).doc(attendanceId).delete();
      return const Right(null);
    } catch (e) {
      debugPrint('출석 기록 삭제 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttendancesByClassId(
    String classId,
  ) async {
    try {
      // 해당 강의의 모든 출석 기록 조회
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('classId', isEqualTo: classId)
              .get();

      // 배치 작업으로 모든 문서 삭제
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return const Right(null);
    } catch (e) {
      debugPrint('강의 출석 기록 일괄 삭제 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 특정 날짜의 특정 강의에 출석한 학생 수를 계산합니다.
  Future<Either<Failure, Map<String, int>>> getAttendanceStatsByDate(
    String classId,
    DateTime date,
  ) async {
    try {
      final result = await getAttendancesByDate(classId, date);

      return result.fold((failure) => Left(failure), (attendances) {
        final stats = {
          'present': 0,
          'late': 0,
          'absent': 0,
          'excused': 0,
          'pending': 0,
          'total': attendances.length,
        };

        for (final attendance in attendances) {
          final status = attendance.status.toString().split('.').last;
          stats[status] = (stats[status] ?? 0) + 1;
        }

        return Right(stats);
      });
    } catch (e) {
      debugPrint('출석 통계 계산 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Wi-Fi CSI 데이터를 출석 기록에 추가합니다.
  Future<Either<Failure, void>> addCsiDataToAttendance(
    String attendanceId,
    Map<String, dynamic> csiData,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(attendanceId).update({
        'csiData': csiData,
      });
      return const Right(null);
    } catch (e) {
      debugPrint('CSI 데이터 추가 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 특정 날짜 범위의 출석 기록을 가져옵니다.
  Future<Either<Failure, List<model.AttendanceModel>>>
  getAttendancesByDateRange(
    String classId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('classId', isEqualTo: classId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .orderBy('date', descending: true)
              .get();

      final attendances =
          snapshot.docs
              .map((doc) => model.AttendanceModel.fromFirestore(doc))
              .toList();

      return Right(attendances);
    } catch (e) {
      debugPrint('날짜 범위 출석 기록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getClassSessions(
    String classId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('sessions')
              .where('classId', isEqualTo: classId)
              .orderBy('startTime', descending: true)
              .get();

      final sessions =
          snapshot.docs.map((doc) {
            final data = doc.data();
            // 원본 Map에서 데이터를 추출한 후 새로운 타입의 Map으로 변환
            final originalMap =
                data['attendanceStatusMap'] as Map<String, dynamic>;
            final attendanceStatusMap = <String, entity.AttendanceStatus>{};

            originalMap.forEach((key, value) {
              attendanceStatusMap[key] = _parseAttendanceStatus(
                value.toString(),
              );
            });

            return SessionEntity(
              id: doc.id,
              classId: data['classId'],
              professorId: data['professorId'],
              startTime: (data['startTime'] as Timestamp).toDate(),
              endTime:
                  data['endTime'] != null
                      ? (data['endTime'] as Timestamp).toDate()
                      : null,
              isActive: data['isActive'] ?? false,
              studentCount: data['studentCount'] ?? 0,
              attendanceStatusMap: attendanceStatusMap,
            );
          }).toList();

      return Right(sessions);
    } catch (e) {
      debugPrint('수업 세션 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SessionEntity>> getActiveSession(
    String classId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('sessions')
              .where('classId', isEqualTo: classId)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return const Left(NotFoundFailure(message: '활성화된 세션이 없습니다.'));
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // 원본 Map에서 데이터를 추출한 후 새로운 타입의 Map으로 변환
      final originalMap =
          data['attendanceStatusMap'] as Map<String, dynamic>? ?? {};
      final attendanceStatusMap = <String, entity.AttendanceStatus>{};

      originalMap.forEach((key, value) {
        attendanceStatusMap[key] = _parseAttendanceStatus(value.toString());
      });

      return Right(
        SessionEntity(
          id: doc.id,
          classId: data['classId'],
          professorId: data['professorId'],
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime:
              data['endTime'] != null
                  ? (data['endTime'] as Timestamp).toDate()
                  : null,
          isActive: data['isActive'] ?? false,
          studentCount: data['studentCount'] ?? 0,
          attendanceStatusMap: attendanceStatusMap,
        ),
      );
    } catch (e) {
      debugPrint('활성 세션 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createSession(
    SessionEntity sessionEntity,
  ) async {
    try {
      final Map<String, dynamic> data = {
        'classId': sessionEntity.classId,
        'professorId': sessionEntity.professorId,
        'startTime': Timestamp.fromDate(sessionEntity.startTime),
        'isActive': sessionEntity.isActive,
        'studentCount': sessionEntity.studentCount,
        'attendanceStatusMap': sessionEntity.attendanceStatusMap.map(
          (key, value) => MapEntry(key, value.toString().split('.').last),
        ),
      };

      if (sessionEntity.endTime != null) {
        data['endTime'] = Timestamp.fromDate(sessionEntity.endTime!);
      }

      final docRef = await _firestore.collection('sessions').add(data);
      return Right(docRef.id);
    } catch (e) {
      debugPrint('세션 생성 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'endTime': Timestamp.fromDate(DateTime.now()),
        'isActive': false,
      });
      return const Right(null);
    } catch (e) {
      debugPrint('세션 종료 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<entity.AttendanceEntity>>> getSessionAttendance(
    String sessionId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('attendances')
              .where('sessionId', isEqualTo: sessionId)
              .get();

      final attendances =
          snapshot.docs.map((doc) {
            final data = doc.data();

            final activityLogs =
                (data['activityLogs'] as List<dynamic>? ?? [])
                    .map(
                      (log) => entity.AttendanceActivityLog(
                        timestamp: (log['timestamp'] as Timestamp).toDate(),
                        isActive: log['isActive'] ?? false,
                        confidenceScore: log['confidenceScore'],
                      ),
                    )
                    .toList();

            return entity.AttendanceEntity(
              id: doc.id,
              classId: data['classId'],
              studentId: data['studentId'],
              sessionId: data['sessionId'],
              date: (data['date'] as Timestamp).toDate(),
              status: _parseAttendanceStatus(data['status']),
              recordedTime: (data['recordedTime'] as Timestamp).toDate(),
              activityLogs: activityLogs,
            );
          }).toList();

      return Right(attendances);
    } catch (e) {
      debugPrint('세션 출석 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ActivityLog>>> getStudentActivityLogs(
    String sessionId,
    String studentId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('activityLogs')
              .where('sessionId', isEqualTo: sessionId)
              .where('studentId', isEqualTo: studentId)
              .orderBy('timestamp', descending: true)
              .get();

      final logs =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return ActivityLog(
              id: doc.id,
              sessionId: data['sessionId'],
              studentId: data['studentId'],
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              isActive: data['isActive'] ?? false,
              confidenceScore: data['confidenceScore'],
              deviceInfo: data['deviceInfo'],
            );
          }).toList();

      return Right(logs);
    } catch (e) {
      debugPrint('학생 활동 로그 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<entity.AttendanceEntity>> watchSessionAttendance(
    String sessionId,
  ) {
    return _firestore
        .collection('attendances')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();

                final activityLogs =
                    (data['activityLogs'] as List<dynamic>? ?? [])
                        .map(
                          (log) => entity.AttendanceActivityLog(
                            timestamp: (log['timestamp'] as Timestamp).toDate(),
                            isActive: log['isActive'] ?? false,
                            confidenceScore: log['confidenceScore'],
                          ),
                        )
                        .toList();

                return entity.AttendanceEntity(
                  id: doc.id,
                  classId: data['classId'],
                  studentId: data['studentId'],
                  sessionId: data['sessionId'],
                  date: (data['date'] as Timestamp).toDate(),
                  status: _parseAttendanceStatus(data['status']),
                  recordedTime: (data['recordedTime'] as Timestamp).toDate(),
                  activityLogs: activityLogs,
                );
              }).toList(),
        );
  }

  @override
  Stream<List<ActivityLog>> watchStudentActivity(
    String sessionId,
    String studentId,
  ) {
    return _firestore
        .collection('activityLogs')
        .where('sessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                return ActivityLog(
                  id: doc.id,
                  sessionId: data['sessionId'],
                  studentId: data['studentId'],
                  timestamp: (data['timestamp'] as Timestamp).toDate(),
                  isActive: data['isActive'] ?? false,
                  confidenceScore: data['confidenceScore'],
                  deviceInfo: data['deviceInfo'],
                );
              }).toList(),
        );
  }

  // 출석 상태 문자열을 enum 타입으로 변환
  entity.AttendanceStatus _parseAttendanceStatus(String? statusStr) {
    if (statusStr == null) return entity.AttendanceStatus.absent;

    switch (statusStr.toLowerCase()) {
      case 'present':
        return entity.AttendanceStatus.present;
      case 'late':
        return entity.AttendanceStatus.late;
      case 'excused':
        return entity.AttendanceStatus.excused;
      case 'absent':
      default:
        return entity.AttendanceStatus.absent;
    }
  }

  // attendance.dart의 AttendanceStatus를 attendance_entity.dart의 AttendanceStatus로 변환
  entity.AttendanceStatus _convertAttendanceStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return entity.AttendanceStatus.present;
      case AttendanceStatus.late:
        return entity.AttendanceStatus.late;
      case AttendanceStatus.excused:
        return entity.AttendanceStatus.excused;
      case AttendanceStatus.absent:
        return entity.AttendanceStatus.absent;
    }
  }
}
