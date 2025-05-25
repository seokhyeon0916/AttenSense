import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../models/attendance_model.dart' as model;
import '../../repositories/attendance_repository.dart';

/// 출석 상태를 업데이트하는 유스케이스
class UpdateAttendanceStatus {
  final AttendanceRepository _repository;

  UpdateAttendanceStatus(this._repository);

  /// 출석 상태 업데이트 실행
  /// @param attendanceId 출석 ID
  /// @param status 업데이트할 출석 상태
  /// @return 성공 또는 실패
  Future<Either<Failure, void>> call(
    String attendanceId,
    model.AttendanceStatus status,
  ) async {
    return await _repository.updateAttendanceStatus(attendanceId, status);
  }
}
