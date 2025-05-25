/// 사용자 역할 열거형
enum UserEntityRole { professor, student }

/// 사용자 엔티티 클래스
class User {
  /// 사용자 고유 식별자
  final String id;

  /// 사용자 이메일
  final String email;

  /// 사용자 이름
  final String name;

  /// 사용자 역할 (교수/학생)
  final UserEntityRole role;

  /// 계정 생성 시간
  final DateTime? createdAt;

  /// 프로필 이미지 URL
  final String? profileImageUrl;

  /// 기본 생성자
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
    this.profileImageUrl,
  });

  /// 교수 여부 확인
  bool get isProfessor => role == UserEntityRole.professor;

  /// 학생 여부 확인
  bool get isStudent => role == UserEntityRole.student;

  /// 사용자 객체 복사본 생성
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserEntityRole? role,
    DateTime? createdAt,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.profileImageUrl == profileImageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        name.hashCode ^
        role.hashCode ^
        createdAt.hashCode ^
        profileImageUrl.hashCode;
  }
}
