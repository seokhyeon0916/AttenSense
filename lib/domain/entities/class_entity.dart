/// 수업 정보를 관리하는 엔티티 클래스
class ClassEntity {
  final String id;
  final String name;
  final String professorId;
  final String roomName;
  final List<String> schedule; // "월 9:00-10:30" 형식
  final List<String> studentIds;
  final DateTime? lastStartTime;
  final DateTime? lastEndTime;
  final bool isActive;

  ClassEntity({
    required this.id,
    required this.name,
    required this.professorId,
    required this.roomName,
    required this.schedule,
    required this.studentIds,
    this.lastStartTime,
    this.lastEndTime,
    this.isActive = false,
  });

  /// 새 수업 생성
  static ClassEntity create({
    required String id,
    required String name,
    required String professorId,
    required String roomName,
    required List<String> schedule,
    List<String> studentIds = const [],
  }) {
    return ClassEntity(
      id: id,
      name: name,
      professorId: professorId,
      roomName: roomName,
      schedule: schedule,
      studentIds: studentIds,
    );
  }

  /// 수업 시작 처리
  ClassEntity startClass() {
    return ClassEntity(
      id: id,
      name: name,
      professorId: professorId,
      roomName: roomName,
      schedule: schedule,
      studentIds: studentIds,
      lastStartTime: DateTime.now(),
      lastEndTime: lastEndTime,
      isActive: true,
    );
  }

  /// 수업 종료 처리
  ClassEntity endClass() {
    return ClassEntity(
      id: id,
      name: name,
      professorId: professorId,
      roomName: roomName,
      schedule: schedule,
      studentIds: studentIds,
      lastStartTime: lastStartTime,
      lastEndTime: DateTime.now(),
      isActive: false,
    );
  }

  /// 학생 추가
  ClassEntity addStudent(String studentId) {
    if (studentIds.contains(studentId)) {
      return this;
    }

    final updatedStudentIds = List<String>.from(studentIds)..add(studentId);

    return ClassEntity(
      id: id,
      name: name,
      professorId: professorId,
      roomName: roomName,
      schedule: schedule,
      studentIds: updatedStudentIds,
      lastStartTime: lastStartTime,
      lastEndTime: lastEndTime,
      isActive: isActive,
    );
  }

  /// 학생 제거
  ClassEntity removeStudent(String studentId) {
    if (!studentIds.contains(studentId)) {
      return this;
    }

    final updatedStudentIds = List<String>.from(studentIds)..remove(studentId);

    return ClassEntity(
      id: id,
      name: name,
      professorId: professorId,
      roomName: roomName,
      schedule: schedule,
      studentIds: updatedStudentIds,
      lastStartTime: lastStartTime,
      lastEndTime: lastEndTime,
      isActive: isActive,
    );
  }
}
