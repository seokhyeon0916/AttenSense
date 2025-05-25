import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/session_repository.dart';

/// 세션 종료 유스케이스
class EndSession {
  final SessionRepository _repository;

  EndSession(this._repository);

  /// 세션 종료 실행
  /// @param sessionId 종료할 세션 ID
  /// @return 성공 또는 실패
  Future<Either<Failure, void>> call(String sessionId) async {
    return await _repository.endSession(sessionId);
  }
}
