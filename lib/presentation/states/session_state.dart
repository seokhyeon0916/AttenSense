import 'package:equatable/equatable.dart';
import '../../domain/entities/session_entity.dart';

/// 세션 관리 화면의 상태를 관리하는 클래스
class SessionState extends Equatable {
  final bool isLoading;
  final bool isActive;
  final String? sessionId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? errorMessage;

  const SessionState({
    required this.isLoading,
    required this.isActive,
    this.sessionId,
    this.startTime,
    this.endTime,
    this.errorMessage,
  });

  /// 초기 상태 생성
  factory SessionState.initial() {
    return const SessionState(isLoading: true, isActive: false);
  }

  /// 로딩 상태 생성
  factory SessionState.loading() =>
      const SessionState(isLoading: true, isActive: false);

  /// 에러 상태 생성
  factory SessionState.error(String message) {
    return SessionState(
      isLoading: false,
      isActive: false,
      errorMessage: message,
    );
  }

  /// 불변 상태 업데이트
  SessionState copyWith({
    bool? isLoading,
    bool? isActive,
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      isActive: isActive ?? this.isActive,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  /// 세션 시작 상태 생성
  factory SessionState.active(String sessionId) {
    return SessionState(
      isLoading: false,
      isActive: true,
      sessionId: sessionId,
      startTime: DateTime.now(),
    );
  }

  /// 세션 종료 상태 생성
  factory SessionState.ended(String sessionId, DateTime startTime) {
    return SessionState(
      isLoading: false,
      isActive: false,
      sessionId: sessionId,
      startTime: startTime,
      endTime: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isActive,
    sessionId,
    startTime,
    endTime,
    errorMessage,
  ];
}
