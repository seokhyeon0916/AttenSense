import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/activity_log.dart';
import '../../repositories/attendance_repository.dart';

/// 학생 활동 로그를 조회하는 유스케이스
class GetStudentActivityLogs {
  final AttendanceRepository _repository;

  GetStudentActivityLogs(this._repository);

  /// 학생 활동 로그 조회 실행
  /// @param sessionId 세션 ID
  /// @param studentId 학생 ID
  /// @return 활동 로그 목록 또는 실패
  Future<Either<Failure, List<ActivityLog>>> call(
    String sessionId,
    String studentId,
  ) async {
    return await _repository.getStudentActivityLogs(sessionId, studentId);
  }
}
