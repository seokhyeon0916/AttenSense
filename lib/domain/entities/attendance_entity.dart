/// 출석 상태 열거형
enum AttendanceStatus {
  present, // 출석
  late, // 지각
  absent, // 결석
  excused, // 공결
}

/// 활동 로그 클래스
class AttendanceActivityLog {
  final DateTime timestamp;
  final bool isActive;
  final double? confidenceScore;

  AttendanceActivityLog({
    required this.timestamp,
    required this.isActive,
    this.confidenceScore,
  });
}

/// 출석 정보를 관리하는 엔티티 클래스
class AttendanceEntity {
  final String id;
  final String classId;
  final String studentId;
  final String sessionId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime recordedTime;
  final List<AttendanceActivityLog> activityLogs;

  AttendanceEntity({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.sessionId,
    required this.date,
    required this.status,
    required this.recordedTime,
    required this.activityLogs,
  });
}
