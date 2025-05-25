import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/session_entity.dart';

/// 세션 및 출석 관리를 위한 레포지토리 인터페이스
abstract class SessionRepository {
  /// 클래스의 모든 세션 목록 조회
  Future<Either<Failure, List<SessionEntity>>> getClassSessions(String classId);

  /// 활성화된 세션 조회
  Future<Either<Failure, SessionEntity>> getActiveSession(String classId);

  /// 세션 생성
  Future<Either<Failure, String>> createSession(SessionEntity sessionEntity);

  /// 세션 종료
  Future<Either<Failure, void>> endSession(String sessionId);

  /// 세션 정보 업데이트
  Future<Either<Failure, void>> updateSession(SessionEntity sessionEntity);

  /// 특정 세션 정보 조회
  Future<Either<Failure, SessionEntity>> getSessionById(String sessionId);

  /// 세션 삭제
  Future<Either<Failure, void>> deleteSession(String sessionId);

  /// 세션 실시간 스트림
  Stream<Either<Failure, SessionEntity>> watchSession(String sessionId);
}
