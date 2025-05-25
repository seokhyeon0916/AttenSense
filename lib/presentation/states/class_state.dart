import 'package:equatable/equatable.dart';
import '../../domain/entities/class_entity.dart';

/// 수업 관리 화면의 상태를 관리하는 클래스
class ClassState extends Equatable {
  final bool isLoading;
  final List<ClassEntity> classes;
  final ClassEntity? selectedClass;
  final String? errorMessage;

  const ClassState({
    required this.isLoading,
    required this.classes,
    this.selectedClass,
    this.errorMessage,
  });

  /// 초기 상태 생성
  factory ClassState.initial() => const ClassState(
    isLoading: false,
    classes: [],
    selectedClass: null,
    errorMessage: null,
  );

  /// 로딩 상태 생성
  factory ClassState.loading() => const ClassState(
    isLoading: true,
    classes: [],
    selectedClass: null,
    errorMessage: null,
  );

  /// 에러 상태 생성
  factory ClassState.error(String message) => ClassState(
    isLoading: false,
    classes: [],
    selectedClass: null,
    errorMessage: message,
  );

  /// 불변 상태 업데이트
  ClassState copyWith({
    bool? isLoading,
    List<ClassEntity>? classes,
    ClassEntity? selectedClass,
    String? errorMessage,
    bool clearError = false,
    bool clearSelectedClass = false,
  }) {
    return ClassState(
      isLoading: isLoading ?? this.isLoading,
      classes: classes ?? this.classes,
      selectedClass:
          clearSelectedClass ? null : (selectedClass ?? this.selectedClass),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, classes, selectedClass, errorMessage];
}
