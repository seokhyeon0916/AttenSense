import '../../entities/attendance_entity.dart' as entity;
import '../../repositories/attendance_repository.dart';

/// 세션 출석 상태를 실시간으로 감시하는 유스케이스
class WatchSessionAttendance {
  final AttendanceRepository _repository;

  WatchSessionAttendance(this._repository);

  /// 세션 출석 감시 실행
  /// @param sessionId 세션 ID
  /// @return 출석 엔티티 목록 스트림
  Stream<List<entity.AttendanceEntity>> call(String sessionId) {
    return _repository.watchSessionAttendance(sessionId);
  }
}
