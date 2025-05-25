import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../entities/user.dart';
import '../../core/error/failures.dart';
import '../../data/models/user_model.dart' show UserModel;

/// 사용자 관리를 위한 Repository 인터페이스
abstract class UserRepository {
  /// 현재 인증된 사용자를 가져옵니다.
  Future<Either<Failure, User?>> getCurrentUser();

  /// 이메일과 비밀번호로 로그인합니다.
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// 이메일과 비밀번호로 회원가입합니다.
  Future<Either<Failure, User>> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserEntityRole role,
  );

  /// 로그아웃합니다.
  Future<Either<Failure, void>> signOut();

  /// 사용자 정보를 업데이트합니다.
  Future<Either<Failure, User>> updateUserInfo(User user);

  /// 프로필 이미지를 업로드합니다.
  Future<Either<Failure, String>> uploadProfileImage(
    String userId,
    String imagePath,
  );

  /// 비밀번호 재설정 이메일을 전송합니다.
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// 모든 사용자 목록을 가져옵니다.
  Future<Either<Failure, List<UserModel>>> getAllUsers();

  /// 역할별 사용자 목록을 가져옵니다.
  Future<Either<Failure, List<UserModel>>> getUsersByRole(UserEntityRole role);

  /// ID로 특정 사용자를 가져옵니다.
  Future<Either<Failure, UserModel?>> getUserById(String userId);

  /// 이메일로 사용자를 가져옵니다.
  Future<Either<Failure, UserModel?>> getUserByEmail(String email);

  /// 새 사용자를 생성합니다.
  Future<Either<Failure, String>> createUser(UserModel user);

  /// 사용자 정보를 업데이트합니다.
  Future<Either<Failure, void>> updateUser(UserModel user);

  /// 사용자를 삭제합니다.
  Future<Either<Failure, void>> deleteUser(String userId);

  /// 사용자에게 강의를 등록합니다.
  Future<Either<Failure, void>> addClassToUser(String userId, String classId);

  /// 사용자에게서 강의를 제거합니다.
  Future<Either<Failure, void>> removeClassFromUser(
    String userId,
    String classId,
  );

  /// 특정 학과의 학생 목록을 가져옵니다.
  Future<Either<Failure, List<UserModel>>> getStudentsByDepartment(
    String department,
  );

  /// 특정 강의를 수강 중인 학생 목록을 가져옵니다.
  Future<Either<Failure, List<UserModel>>> getStudentsByClassId(String classId);

  /// 기기 정보를 사용자 정보에 업데이트합니다.
  Future<Either<Failure, void>> updateUserDeviceInfo(
    String userId,
    Map<String, dynamic> deviceInfo,
  );
}
