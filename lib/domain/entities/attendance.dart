import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, late, absent, excused }

class Attendance extends Equatable {
  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String? comment;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;

  const Attendance({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.status,
    this.comment,
    required this.createdAt,
    this.lastUpdatedAt,
  });

  bool get isPresent => status == AttendanceStatus.present;
  bool get isLate => status == AttendanceStatus.late;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isExcused => status == AttendanceStatus.excused;

  @override
  List<Object?> get props => [
    id,
    classId,
    studentId,
    date,
    status,
    comment,
    createdAt,
    lastUpdatedAt,
  ];
}
