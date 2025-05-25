import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/session_entity.dart';
import '../../repositories/session_repository.dart';

/// 클래스의 활성 세션을 가져오는 유스케이스
class GetActiveSession {
  final SessionRepository _repository;

  GetActiveSession(this._repository);

  /// 활성 세션 조회 실행
  /// @param classId 클래스 ID
  /// @return 세션 엔티티 또는 실패
  Future<Either<Failure, SessionEntity>> call(String classId) async {
    return await _repository.getActiveSession(classId);
  }
}
