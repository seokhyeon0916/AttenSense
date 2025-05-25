import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/usecases/session/get_active_session.dart';
import '../../domain/usecases/session/create_session.dart';
import '../../domain/usecases/session/end_session.dart';
import '../../core/error/failures.dart';
import '../states/session_state.dart';

// 유스케이스 프로바이더들
final getActiveSessionProvider = Provider<GetActiveSession>((ref) {
  return GetActiveSession(ref.read(sessionRepositoryProvider));
});

final createSessionProvider = Provider<CreateSession>((ref) {
  return CreateSession(ref.read(sessionRepositoryProvider));
});

final endSessionProvider = Provider<EndSession>((ref) {
  return EndSession(ref.read(sessionRepositoryProvider));
});

// 외부 의존성으로 레포지토리 프로바이더 제공 (DI 계층에서 실제 구현)
final sessionRepositoryProvider = Provider((ref) {
  throw UnimplementedError('Provider not implemented');
});

// 클래스별 활성 세션 프로바이더
final activeSessionProvider =
    StateNotifierProvider.family<SessionNotifier, SessionState, String>((
      ref,
      classId,
    ) {
      return SessionNotifier(
        getActiveSession: ref.read(getActiveSessionProvider),
        createSession: ref.read(createSessionProvider),
        endSession: ref.read(endSessionProvider),
        classId: classId,
      );
    });

class SessionNotifier extends StateNotifier<SessionState> {
  final GetActiveSession _getActiveSession;
  final CreateSession _createSession;
  final EndSession _endSession;
  final String classId;

  SessionNotifier({
    required GetActiveSession getActiveSession,
    required CreateSession createSession,
    required EndSession endSession,
    required this.classId,
  }) : _getActiveSession = getActiveSession,
       _createSession = createSession,
       _endSession = endSession,
       super(SessionState.initial()) {
    // 초기화 시 활성 세션 확인
    checkActiveSession();
  }

  Future<void> checkActiveSession() async {
    state = state.copyWith(isLoading: true);

    final result = await _getActiveSession(classId);

    state = result.fold(
      (failure) {
        if (failure.message == 'No active session found') {
          return state.copyWith(
            isLoading: false,
            isActive: false,
            sessionId: null,
            clearError: true,
          );
        }
        return state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (session) => state.copyWith(
        isLoading: false,
        isActive: session.isActive,
        sessionId: session.id,
        startTime: session.startTime,
        endTime: session.endTime,
        clearError: true,
      ),
    );
  }

  Future<bool> startSession() async {
    state = state.copyWith(isLoading: true);

    final sessionEntity = SessionEntity(
      id: '', // ID는 저장 시 생성됨
      classId: classId,
      professorId: 'current_professor_id', // 현재 로그인한 교수 ID를 가져오는 로직 필요
      startTime: DateTime.now(),
      isActive: true,
      studentCount: 0, // 초기 학생 수는 0
      attendanceStatusMap: {}, // 초기 출석 상태는 빈 맵
    );

    final result = await _createSession(sessionEntity);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        return false;
      },
      (sessionId) {
        state = SessionState.active(sessionId);
        return true;
      },
    );

    return state.errorMessage == null;
  }

  Future<bool> endSession() async {
    if (state.sessionId == null) {
      state = state.copyWith(errorMessage: '활성화된 세션이 없습니다');
      return false;
    }

    state = state.copyWith(isLoading: true);

    final result = await _endSession(state.sessionId!);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        return false;
      },
      (_) {
        state = SessionState.ended(
          state.sessionId!,
          state.startTime ?? DateTime.now(),
        );
        return true;
      },
    );

    return state.errorMessage == null;
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message ?? '서버 오류가 발생했습니다';
      case NetworkFailure:
        return '네트워크 연결을 확인해주세요';
      default:
        return '알 수 없는 오류가 발생했습니다';
    }
  }
}
