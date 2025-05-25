import '../../domain/entities/attendance.dart';

class AttendanceModel extends Attendance {
  const AttendanceModel({
    required super.id,
    required super.classId,
    required super.studentId,
    required super.date,
    required super.status,
    super.comment,
    required super.createdAt,
    super.lastUpdatedAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      classId: json['classId'] as String,
      studentId: json['studentId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: _parseAttendanceStatus(json['status'] as String),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt:
          json['lastUpdatedAt'] != null
              ? DateTime.parse(json['lastUpdatedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  static AttendanceStatus _parseAttendanceStatus(String status) {
    switch (status) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        throw ArgumentError('Invalid attendance status: $status');
    }
  }
}
