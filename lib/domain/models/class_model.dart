import 'package:cloud_firestore/cloud_firestore.dart';

/// 수업 정보를 관리하는 모델 클래스
class ClassModel {
  final String id;
  final String name;
  final String professorId;
  final String professorName;
  final String location;
  final String description;
  final List<Map<String, dynamic>>
  schedule; // [{day: '월', startTime: '09:00', endTime: '12:00'}]
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.professorId,
    required this.professorName,
    required this.location,
    required this.description,
    required this.schedule,
    required this.studentIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서에서 ClassModel 객체를 생성합니다.
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      professorId: data['professorId'] ?? '',
      professorName: data['professorName'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      schedule: List<Map<String, dynamic>>.from(data['schedule'] ?? []),
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// ClassModel 객체를 Firestore 문서 데이터로 변환합니다.
  Map<String, dynamic> toFirestore() {
    // 디버깅을 위한 로그 추가
    print('ClassModel.toFirestore - studentIds: $studentIds');

    return {
      'name': name,
      'professorId': professorId,
      'professorName': professorName,
      'location': location,
      'description': description,
      'schedule': schedule,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 특정 필드만 업데이트할 수 있는 복사 생성자
  ClassModel copyWith({
    String? name,
    String? location,
    String? description,
    List<Map<String, dynamic>>? schedule,
    List<String>? studentIds,
  }) {
    return ClassModel(
      id: id,
      name: name ?? this.name,
      professorId: professorId,
      professorName: professorName,
      location: location ?? this.location,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
