import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/user.dart';

/// 사용자 정보를 관리하는 모델 클래스
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserEntityRole role;
  final String idNumber; // 학번 또는 교번
  final String department;
  final String? phoneNumber;
  final String? profileImageUrl;
  final Map<String, dynamic>? deviceInfo; // 기기 정보
  final List<String>? enrolledClassIds; // 수강 또는 담당 수업 ID 목록
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.idNumber,
    required this.department,
    this.phoneNumber,
    this.profileImageUrl,
    this.deviceInfo,
    this.enrolledClassIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서에서 UserModel 객체를 생성합니다.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: _parseUserRole(data['role']),
      idNumber: data['idNumber'] ?? '',
      department: data['department'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      deviceInfo: data['deviceInfo'],
      enrolledClassIds:
          data['enrolledClassIds'] != null
              ? List<String>.from(data['enrolledClassIds'])
              : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// UserModel 객체를 Firestore 문서 데이터로 변환합니다.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'idNumber': idNumber,
      'department': department,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'deviceInfo': deviceInfo,
      'enrolledClassIds': enrolledClassIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 문자열에서 UserEntityRole로 변환하는 도우미 함수
  static UserEntityRole _parseUserRole(String? roleStr) {
    if (roleStr == null) return UserEntityRole.student;

    switch (roleStr) {
      case 'professor':
        return UserEntityRole.professor;
      default:
        return UserEntityRole.student;
    }
  }

  /// 사용자 정보를 업데이트하는 복사 생성자
  UserModel copyWith({
    String? name,
    String? email,
    String? department,
    String? phoneNumber,
    String? profileImageUrl,
    Map<String, dynamic>? deviceInfo,
    List<String>? enrolledClassIds,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      idNumber: idNumber,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      enrolledClassIds: enrolledClassIds ?? this.enrolledClassIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 사용자가 교수인지 확인합니다.
  bool get isProfessor => role == UserEntityRole.professor;

  /// 사용자가 학생인지 확인합니다.
  bool get isStudent => role == UserEntityRole.student;
}
