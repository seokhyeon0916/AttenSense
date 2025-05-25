import '../../domain/entities/class.dart';

class ClassModel extends Class {
  const ClassModel({
    required super.id,
    required super.name,
    required super.professorId,
    super.location,
    required super.weekDay,
    required super.startTime,
    required super.endTime,
    super.status = ClassStatus.scheduled,
    super.studentIds = const [],
    required super.createdAt,
    super.lastUpdatedAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      professorId: json['professorId'] as String,
      location: json['location'] as String?,
      weekDay: _parseWeekDay(json['weekDay'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: _parseClassStatus(json['status'] as String),
      studentIds:
          (json['studentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt:
          json['lastUpdatedAt'] != null
              ? DateTime.parse(json['lastUpdatedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'professorId': professorId,
      'location': location,
      'weekDay': weekDay.toString().split('.').last,
      'startTime': startTime,
      'endTime': endTime,
      'status': status.toString().split('.').last,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  static WeekDay _parseWeekDay(String weekDay) {
    switch (weekDay) {
      case 'monday':
        return WeekDay.monday;
      case 'tuesday':
        return WeekDay.tuesday;
      case 'wednesday':
        return WeekDay.wednesday;
      case 'thursday':
        return WeekDay.thursday;
      case 'friday':
        return WeekDay.friday;
      case 'saturday':
        return WeekDay.saturday;
      case 'sunday':
        return WeekDay.sunday;
      default:
        throw ArgumentError('Invalid week day: $weekDay');
    }
  }

  static ClassStatus _parseClassStatus(String status) {
    switch (status) {
      case 'scheduled':
        return ClassStatus.scheduled;
      case 'inProgress':
        return ClassStatus.inProgress;
      case 'completed':
        return ClassStatus.completed;
      case 'cancelled':
        return ClassStatus.cancelled;
      default:
        throw ArgumentError('Invalid class status: $status');
    }
  }
}
