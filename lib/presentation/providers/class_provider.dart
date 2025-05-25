import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/class.dart' as domain;
import '../../domain/usecases/class/get_professor_classes.dart';
import '../../domain/usecases/class/create_class.dart';
import '../../domain/usecases/class/update_class.dart';
import '../../domain/usecases/class/delete_class.dart';
import '../../domain/usecases/class/start_class.dart';
import '../../domain/usecases/class/end_class.dart';
import '../../core/error/failures.dart';
import '../states/class_state.dart';

/// Domain.Class를 ClassEntity로 변환하는 확장 메서드
extension ClassMapping on domain.Class {
  ClassEntity toEntity() {
    return ClassEntity(
      id: id,
      name: name,
      professorId: professorId,
      roomName: location ?? '지정되지 않음',
      schedule: ['${weekDay.toString().split('.').last} $startTime-$endTime'],
      studentIds: studentIds,
      isActive: status == domain.ClassStatus.inProgress,
    );
  }
}

/// ClassEntity를 Domain.Class로 변환하는 확장 메서드
extension ClassEntityMapping on ClassEntity {
  domain.Class toDomain() {
    final scheduleInfo =
        schedule.isNotEmpty ? schedule[0].split(' ') : ['monday', '9:00-10:30'];
    final day = scheduleInfo[0].toLowerCase();
    final timeRange = scheduleInfo.length > 1 ? scheduleInfo[1] : '9:00-10:30';
    final times = timeRange.split('-');

    domain.WeekDay weekDay;
    switch (day) {
      case 'monday':
        weekDay = domain.WeekDay.monday;
        break;
      case 'tuesday':
        weekDay = domain.WeekDay.tuesday;
        break;
      case 'wednesday':
        weekDay = domain.WeekDay.wednesday;
        break;
      case 'thursday':
        weekDay = domain.WeekDay.thursday;
        break;
      case 'friday':
        weekDay = domain.WeekDay.friday;
        break;
      case 'saturday':
        weekDay = domain.WeekDay.saturday;
        break;
      case 'sunday':
        weekDay = domain.WeekDay.sunday;
        break;
      default:
        weekDay = domain.WeekDay.monday;
    }

    return domain.Class(
      id: id,
      name: name,
      professorId: professorId,
      location: roomName,
      weekDay: weekDay,
      startTime: times[0],
      endTime: times.length > 1 ? times[1] : '10:30',
      status:
          isActive
              ? domain.ClassStatus.inProgress
              : domain.ClassStatus.scheduled,
      studentIds: studentIds,
      createdAt: DateTime.now(),
    );
  }
}

// 사용자 ID 프로바이더
final currentUserIdProvider = StateProvider<String>((ref) => '');

// 유스케이스 프로바이더들
final getProfessorClassesProvider = Provider<GetProfessorClasses>((ref) {
  return GetProfessorClasses(ref.read(classRepositoryProvider));
});

final createClassProvider = Provider<CreateClass>((ref) {
  return CreateClass(ref.read(classRepositoryProvider));
});

final updateClassProvider = Provider<UpdateClass>((ref) {
  return UpdateClass(ref.read(classRepositoryProvider));
});

final deleteClassProvider = Provider<DeleteClass>((ref) {
  return DeleteClass(ref.read(classRepositoryProvider));
});

final startClassProvider = Provider<StartClass>((ref) {
  return StartClass(ref.read(classRepositoryProvider));
});

final endClassProvider = Provider<EndClass>((ref) {
  return EndClass(ref.read(classRepositoryProvider));
});

// 외부 의존성으로 레포지토리 프로바이더 제공 (DI 계층에서 실제 구현)
final classRepositoryProvider = Provider((ref) {
  throw UnimplementedError('Provider not implemented');
});

// 교수의 수업 목록 프로바이더
final professorClassesProvider =
    StateNotifierProvider<ClassNotifier, ClassState>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      return ClassNotifier(
        getProfessorClasses: ref.read(getProfessorClassesProvider),
        createClass: ref.read(createClassProvider),
        updateClass: ref.read(updateClassProvider),
        deleteClass: ref.read(deleteClassProvider),
        startClass: ref.read(startClassProvider),
        endClass: ref.read(endClassProvider),
        userId: userId,
      );
    });

// 특정 수업 상세 정보 프로바이더
final classDetailProvider = Provider.family<ClassState, String>((ref, classId) {
  final classState = ref.watch(professorClassesProvider);
  final selectedClass = classState.classes.firstWhere(
    (classEntity) => classEntity.id == classId,
    orElse: () => throw Exception('수업을 찾을 수 없습니다'),
  );

  return classState.copyWith(selectedClass: selectedClass);
});

class ClassNotifier extends StateNotifier<ClassState> {
  final GetProfessorClasses _getProfessorClasses;
  final CreateClass _createClass;
  final UpdateClass _updateClass;
  final DeleteClass _deleteClass;
  final StartClass _startClass;
  final EndClass _endClass;
  final String userId;

  ClassNotifier({
    required GetProfessorClasses getProfessorClasses,
    required CreateClass createClass,
    required UpdateClass updateClass,
    required DeleteClass deleteClass,
    required StartClass startClass,
    required EndClass endClass,
    required this.userId,
  }) : _getProfessorClasses = getProfessorClasses,
       _createClass = createClass,
       _updateClass = updateClass,
       _deleteClass = deleteClass,
       _startClass = startClass,
       _endClass = endClass,
       super(ClassState.initial()) {
    if (userId.isNotEmpty) {
      fetchClasses();
    }
  }

  Future<void> fetchClasses() async {
    state = state.copyWith(isLoading: true);

    final result = await _getProfessorClasses(userId);

    state = result.fold(
      (failure) => state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (classes) => state.copyWith(
        isLoading: false,
        classes: classes.map((cls) => cls.toEntity()).toList(),
        errorMessage: null,
      ),
    );
  }

  Future<bool> createNewClass(ClassEntity classEntity) async {
    state = state.copyWith(isLoading: true);

    final result = await _createClass(classEntity.toDomain());

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        return false;
      },
      (classId) {
        fetchClasses();
        return true;
      },
    );

    return state.errorMessage == null;
  }

  Future<bool> updateExistingClass(ClassEntity classEntity) async {
    state = state.copyWith(isLoading: true);

    final result = await _updateClass(classEntity.toDomain());

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        return false;
      },
      (_) {
        fetchClasses();
        return true;
      },
    );

    return state.errorMessage == null;
  }

  Future<bool> deleteExistingClass(String classId) async {
    state = state.copyWith(isLoading: true);

    final result = await _deleteClass(classId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        return false;
      },
      (_) {
        fetchClasses();
        return true;
      },
    );

    return state.errorMessage == null;
  }

  Future<bool> startClass(String classId) async {
    state = state.copyWith(isLoading: true);

    final result = await _startClass(classId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        return false;
      },
      (_) {
        fetchClasses();
        return true;
      },
    );

    return state.errorMessage == null;
  }

  Future<bool> endClass(String classId) async {
    state = state.copyWith(isLoading: true);

    final result = await _endClass(classId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        return false;
      },
      (_) {
        fetchClasses();
        return true;
      },
    );

    return state.errorMessage == null;
  }

  void selectClass(String classId) {
    final selectedClass = state.classes.firstWhere(
      (classEntity) => classEntity.id == classId,
      orElse: () => throw Exception('수업을 찾을 수 없습니다'),
    );

    state = state.copyWith(selectedClass: selectedClass);
  }

  void clearSelectedClass() {
    state = state.copyWith(clearSelectedClass: true);
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
