import 'attendance_entity.dart';

/// 수업 세션 정보를 관리하는 엔티티 클래스
class SessionEntity {
  final String id;
  final String classId;
  final String professorId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final int studentCount;
  final Map<String, AttendanceStatus> attendanceStatusMap;

  SessionEntity({
    required this.id,
    required this.classId,
    required this.professorId,
    required this.startTime,
    this.endTime,
    required this.isActive,
    required this.studentCount,
    required this.attendanceStatusMap,
  });

  /// 세션이 활성 상태인지 확인
  bool get isSessionActive => isActive && endTime == null;

  /// 세션 종료 처리
  SessionEntity endSession() {
    return SessionEntity(
      id: id,
      classId: classId,
      professorId: professorId,
      startTime: startTime,
      endTime: DateTime.now(),
      isActive: false,
      studentCount: studentCount,
      attendanceStatusMap: attendanceStatusMap,
    );
  }
}
