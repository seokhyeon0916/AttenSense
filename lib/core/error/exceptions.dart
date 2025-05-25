/// 서버 관련 예외
class ServerException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  ServerException({required this.message, this.stackTrace});

  @override
  String toString() => 'ServerException: $message';
}

/// 캐시 관련 예외
class CacheException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  CacheException({required this.message, this.stackTrace});

  @override
  String toString() => 'CacheException: $message';
}

/// 네트워크 관련 예외
class NetworkException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  NetworkException({this.message = '인터넷 연결을 확인해주세요.', this.stackTrace});

  @override
  String toString() => 'NetworkException: $message';
}

/// 인증 관련 예외
class AuthException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  AuthException({required this.message, this.code, this.stackTrace});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// 데이터 미발견 예외
class NotFoundException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  NotFoundException({this.message = '요청한 데이터를 찾을 수 없습니다.', this.stackTrace});

  @override
  String toString() => 'NotFoundException: $message';
}

/// CSI 데이터 수집 관련 예외
class CSIDataException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  CSIDataException({required this.message, this.stackTrace});

  @override
  String toString() => 'CSIDataException: $message';
}

/// 유효성 검사 관련 예외
class ValidationException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  ValidationException({required this.message, this.stackTrace});

  @override
  String toString() => 'ValidationException: $message';
}

/// 권한 관련 예외
class PermissionException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  PermissionException({this.message = '권한이 없습니다.', this.stackTrace});

  @override
  String toString() => 'PermissionException: $message';
}
