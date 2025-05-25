import '../../domain/entities/user.dart';

/// User 엔티티의 데이터 모델 구현
class UserModel extends User {
  /// 기본 생성자
  UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role, // 직접 UserEntityRole 사용
    super.createdAt,
    super.profileImageUrl,
  });

  /// User 엔티티에서 UserModel 객체 생성
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role, // 이미 UserEntityRole 타입
      createdAt: user.createdAt,
      profileImageUrl: user.profileImageUrl,
    );
  }

  /// Firebase 데이터에서 UserModel 객체 생성
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final roleString = map['role'] as String;
    final userRole =
        roleString.toLowerCase() == 'professor'
            ? UserEntityRole.professor
            : UserEntityRole.student;

    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      role: userRole,
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : null,
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  /// UserModel 객체를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role == UserEntityRole.professor ? 'professor' : 'student',
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'profileImageUrl': profileImageUrl,
    };
  }

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, name: $name, role: $role, createdAt: $createdAt, profileImageUrl: $profileImageUrl}';
  }
}
