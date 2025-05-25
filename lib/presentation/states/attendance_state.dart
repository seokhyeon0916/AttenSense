import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_entity.dart' as entity;

/// 출석 관리 화면의 상태를 관리하는 클래스
class AttendanceState extends Equatable {
  final bool isLoading;
  final List<entity.AttendanceEntity> attendances;
  final String? selectedStudentId;
  final String? errorMessage;

  const AttendanceState({
    required this.isLoading,
    required this.attendances,
    this.selectedStudentId,
    this.errorMessage,
  });

  /// 초기 상태 생성
  factory AttendanceState.initial() => const AttendanceState(
    isLoading: false,
    attendances: [],
    selectedStudentId: null,
    errorMessage: null,
  );

  /// 로딩 상태 생성
  factory AttendanceState.loading() => const AttendanceState(
    isLoading: true,
    attendances: [],
    selectedStudentId: null,
    errorMessage: null,
  );

  /// 에러 상태 생성
  factory AttendanceState.error(String message) => AttendanceState(
    isLoading: false,
    attendances: [],
    selectedStudentId: null,
    errorMessage: message,
  );

  /// 로드 상태 생성
  factory AttendanceState.loaded(List<entity.AttendanceEntity> attendances) {
    return AttendanceState(
      isLoading: false,
      attendances: attendances,
      selectedStudentId: null,
      errorMessage: null,
    );
  }

  /// 불변 상태 업데이트
  AttendanceState copyWith({
    bool? isLoading,
    List<entity.AttendanceEntity>? attendances,
    String? selectedStudentId,
    String? errorMessage,
    bool clearError = false,
    bool clearSelectedStudent = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      attendances: attendances ?? this.attendances,
      selectedStudentId:
          clearSelectedStudent
              ? null
              : (selectedStudentId ?? this.selectedStudentId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    attendances,
    selectedStudentId,
    errorMessage,
  ];
}
