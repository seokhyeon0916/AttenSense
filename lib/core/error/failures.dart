import 'package:equatable/equatable.dart';

/// 애플리케이션에서 발생할 수 있는 모든 실패 유형의 기본 클래스
abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure({required this.message, this.stackTrace});

  @override
  List<Object?> get props => [message, stackTrace];
}

/// 서버 관련 오류가 발생했을 때의 실패 유형
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.stackTrace});
}

/// 캐시(로컬 데이터) 관련 오류가 발생했을 때의 실패 유형
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.stackTrace});
}

/// 네트워크 연결 오류가 발생했을 때의 실패 유형
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = '인터넷 연결을 확인해주세요.', super.stackTrace});
}

/// 인증 관련 오류가 발생했을 때의 실패 유형
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.stackTrace});
}

/// 권한 관련 오류가 발생했을 때의 실패 유형
class PermissionFailure extends Failure {
  const PermissionFailure({super.message = '권한이 없습니다.', super.stackTrace});
}

/// 유효성 검사 오류가 발생했을 때의 실패 유형
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.stackTrace});
}

/// 데이터가 존재하지 않을 때의 실패 유형
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = '요청한 데이터를 찾을 수 없습니다.',
    super.stackTrace,
  });
}
