import 'package:equatable/equatable.dart';

enum ClassStatus { scheduled, inProgress, completed, cancelled }

enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class Class extends Equatable {
  final String id;
  final String name;
  final String professorId;
  final String? location;
  final WeekDay weekDay;
  final String startTime;
  final String endTime;
  final ClassStatus status;
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;

  const Class({
    required this.id,
    required this.name,
    required this.professorId,
    this.location,
    required this.weekDay,
    required this.startTime,
    required this.endTime,
    this.status = ClassStatus.scheduled,
    this.studentIds = const [],
    required this.createdAt,
    this.lastUpdatedAt,
  });

  bool get isInProgress => status == ClassStatus.inProgress;

  /// 현재 객체의 복사본을 생성하고 지정된 속성 값을 업데이트합니다.
  Class copyWith({
    String? id,
    String? name,
    String? professorId,
    String? location,
    WeekDay? weekDay,
    String? startTime,
    String? endTime,
    ClassStatus? status,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Class(
      id: id ?? this.id,
      name: name ?? this.name,
      professorId: professorId ?? this.professorId,
      location: location ?? this.location,
      weekDay: weekDay ?? this.weekDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    professorId,
    location,
    weekDay,
    startTime,
    endTime,
    status,
    studentIds,
    createdAt,
    lastUpdatedAt,
  ];
}
