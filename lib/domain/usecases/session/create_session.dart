import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/session_entity.dart';
import '../../repositories/session_repository.dart';

/// 세션 생성 유스케이스
class CreateSession {
  final SessionRepository _repository;

  CreateSession(this._repository);

  /// 세션 생성 실행
  /// @param sessionEntity 생성할 세션 엔티티
  /// @return 생성된 세션 ID 또는 실패
  Future<Either<Failure, String>> call(SessionEntity sessionEntity) async {
    return await _repository.createSession(sessionEntity);
  }
}
