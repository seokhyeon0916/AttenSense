import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/attendance_entity.dart' as entity;
import '../../domain/entities/activity_log.dart';
import '../../domain/models/attendance_model.dart' as model;
import '../../domain/usecases/attendance/watch_session_attendance.dart';
import '../../domain/usecases/attendance/update_attendance_status.dart';
import '../../domain/usecases/attendance/get_student_activity_logs.dart';
import '../../core/error/failures.dart';
import '../states/attendance_state.dart';

// 유스케이스 프로바이더들
final watchSessionAttendanceProvider = Provider<WatchSessionAttendance>((ref) {
  return WatchSessionAttendance(ref.read(attendanceRepositoryProvider));
});

final updateAttendanceStatusProvider = Provider<UpdateAttendanceStatus>((ref) {
  return UpdateAttendanceStatus(ref.read(attendanceRepositoryProvider));
});

final getStudentActivityLogsProvider = Provider<GetStudentActivityLogs>((ref) {
  return GetStudentActivityLogs(ref.read(attendanceRepositoryProvider));
});

// 외부 의존성으로 레포지토리 프로바이더 제공 (DI 계층에서 실제 구현)
final attendanceRepositoryProvider = Provider((ref) {
  throw UnimplementedError('Provider not implemented');
});

// 세션별 출석 상태 프로바이더
final sessionAttendanceProvider =
    StateNotifierProvider.family<AttendanceNotifier, AttendanceState, String>((
      ref,
      sessionId,
    ) {
      return AttendanceNotifier(
        watchSessionAttendance: ref.read(watchSessionAttendanceProvider),
        updateAttendanceStatus: ref.read(updateAttendanceStatusProvider),
        getStudentActivityLogs: ref.read(getStudentActivityLogsProvider),
        sessionId: sessionId,
      );
    });

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final WatchSessionAttendance _watchSessionAttendance;
  final UpdateAttendanceStatus _updateAttendanceStatus;
  final GetStudentActivityLogs _getStudentActivityLogs;
  final String sessionId;

  // 스트림 구독 취소를 위한 변수
  Stream<List<entity.AttendanceEntity>>? _attendanceStream;

  AttendanceNotifier({
    required WatchSessionAttendance watchSessionAttendance,
    required UpdateAttendanceStatus updateAttendanceStatus,
    required GetStudentActivityLogs getStudentActivityLogs,
    required this.sessionId,
  }) : _watchSessionAttendance = watchSessionAttendance,
       _updateAttendanceStatus = updateAttendanceStatus,
       _getStudentActivityLogs = getStudentActivityLogs,
       super(AttendanceState.initial()) {
    // 초기화 시 출석 데이터 로드
    loadAttendances();
  }

  void loadAttendances() {
    state = state.copyWith(isLoading: true);

    try {
      _attendanceStream = _watchSessionAttendance(sessionId);

      _attendanceStream!.listen(
        (attendances) {
          state = state.copyWith(
            isLoading: false,
            attendances: attendances,
            clearError: true,
          );
        },
        onError: (error) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: error.toString(),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateAttendanceStatus(
    String attendanceId,
    model.AttendanceStatus status,
  ) async {
    state = state.copyWith(isLoading: true);

    final result = await _updateAttendanceStatus(attendanceId, status);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (_) {
        state = state.copyWith(isLoading: false, clearError: true);
      },
    );
  }

  Future<List<ActivityLog>> getStudentActivityLogs(String studentId) async {
    final result = await _getStudentActivityLogs(sessionId, studentId);

    return result.fold((failure) {
      state = state.copyWith(errorMessage: _mapFailureToMessage(failure));
      return [];
    }, (logs) => logs);
  }

  void selectStudent(String studentId) {
    state = state.copyWith(selectedStudentId: studentId);
  }

  void clearSelectedStudent() {
    state = state.copyWith(clearSelectedStudent: true);
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

  @override
  void dispose() {
    // 스트림 구독 취소
    _attendanceStream = null;
    super.dispose();
  }
}
