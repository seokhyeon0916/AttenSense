import 'package:equatable/equatable.dart';

/// 학생의 활동 로그를 나타내는 엔티티 클래스
class ActivityLog extends Equatable {
  final String id;
  final String sessionId;
  final String studentId;
  final DateTime timestamp;
  final bool isActive;
  final double? confidenceScore;
  final Map<String, dynamic>? deviceInfo;

  const ActivityLog({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.timestamp,
    required this.isActive,
    this.confidenceScore,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [
    id,
    sessionId,
    studentId,
    timestamp,
    isActive,
    confidenceScore,
    deviceInfo,
  ];
}
