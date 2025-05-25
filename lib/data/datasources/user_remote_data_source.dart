import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../core/error/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart' as domain;

abstract class UserRemoteDataSource {
  /// 현재 로그인된 사용자 정보를 가져옵니다.
  ///
  /// [AuthException]이 발생할 수 있습니다.
  Future<UserModel?> getCurrentUser();

  /// 이메일과 비밀번호로 로그인합니다.
  ///
  /// [AuthException]이 발생할 수 있습니다.
  Future<UserModel> signInWithEmailAndPassword(String email, String password);

  /// 이메일과 비밀번호로 회원가입합니다.
  ///
  /// [AuthException]이 발생할 수 있습니다.
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    domain.UserEntityRole role,
  );

  /// 로그아웃합니다.
  ///
  /// [AuthException]이 발생할 수 있습니다.
  Future<void> signOut();

  /// 사용자 정보를 업데이트합니다.
  ///
  /// [ServerException]이 발생할 수 있습니다.
  Future<UserModel> updateUserInfo(UserModel user);

  /// 사용자 ID로 사용자 정보를 가져옵니다.
  ///
  /// [ServerException]이나 [NotFoundException]이 발생할 수 있습니다.
  Future<UserModel?> getUserById(String userId);

  /// 프로필 이미지를 업로드합니다.
  ///
  /// [ServerException]이 발생할 수 있습니다.
  Future<String> uploadProfileImage(String userId, String imagePath);

  /// 비밀번호 재설정 이메일을 발송합니다.
  ///
  /// [AuthException]이 발생할 수 있습니다.
  Future<void> sendPasswordResetEmail(String email);

  /// 모든 사용자 목록을 가져옵니다.
  ///
  /// [ServerException]이 발생할 수 있습니다.
  Future<List<UserModel>> getAllUsers();

  /// 역할별 사용자 목록을 가져옵니다.
  ///
  /// [ServerException]이 발생할 수 있습니다.
  Future<List<UserModel>> getUsersByRole(domain.UserEntityRole role);

  /// 이메일로 사용자를 가져옵니다.
  ///
  /// [ServerException]이나 [NotFoundException]이 발생할 수 있습니다.
  Future<UserModel?> getUserByEmail(String email);

  /// 새 사용자를 생성합니다.
  ///
  /// [ServerException]이 발생할 수 있습니다.
  Future<String> createUser(UserModel user);

  /// 사용자 정보를 업데이트합니다.
  ///
  /// [ServerException]이나 [NotFoundException]이 발생할 수 있습니다.
  Future<void> updateUser(UserModel user);

  /// 사용자를 삭제합니다.
  ///
  /// [ServerException]이나 [NotFoundException]이 발생할 수 있습니다.
  Future<void> deleteUser(String userId);

  /// 사용자에게 강의를 등록합니다.
  ///
  /// [ServerException]이나 [NotFoundException]이 발생할 수 있습니다.
  Future<void> addClassToUser(String userId, String classId);

  /// 사용자에게서 강의를 제거합니다.
  ///
  /// [ServerException]이나 [NotFoundException]이 발생할 수 있습니다.
  Future<void> removeClassFromUser(String userId, String classId);

  /// 특정 학과의 학생 목록을 가져옵니다.
  ///
  /// [ServerException]이 발생할 수 있습니다.
  Future<List<UserModel>> getStudentsByDepartment(String department);

  /// 특정 강의를 수강 중인 학생 목록을 가져옵니다.
  ///
  /// [ServerException]이 발생할 수 있습니다.
  Future<List<UserModel>> getStudentsByClassId(String classId);

  /// 기기 정보를 사용자 정보에 업데이트합니다.
  ///
  /// [ServerException]이나 [NotFoundException]이 발생할 수 있습니다.
  Future<void> updateUserDeviceInfo(
    String userId,
    Map<String, dynamic> deviceInfo,
  );
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  UserRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.storage,
  });

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw ServerException(message: '사용자가 로그인되어 있지 않습니다.');
      }

      final userDoc =
          await firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        throw ServerException(message: '사용자 정보를 찾을 수 없습니다.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      userData['id'] = firebaseUser.uid;

      return UserModel.fromMap(userData);
    } catch (e) {
      throw ServerException(message: '사용자 정보 조회 오류: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    print('UserRemoteDataSource: 간소화된 로그인 메서드 시작');
    print('로그인 시도: 이메일=$email');

    try {
      // 버전 충돌 문제로 인한 오류를 방지하기 위한 방식으로 변경
      print('Firebase Auth 로그인 직접 호출');

      // 먼저 로그아웃하여 이전 세션을 정리
      await firebaseAuth.signOut();

      // 이메일과 비밀번호를 사용한 로그인 시도
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 로그인 후 현재 사용자 가져오기
      final user = firebaseAuth.currentUser;
      if (user == null) {
        print('사용자 정보가 null입니다');
        throw ServerException(message: '로그인 후 사용자 정보를 가져올 수 없습니다');
      }

      print('Firebase Auth 로그인 성공: uid=${user.uid}');

      // Firestore에서 사용자 정보 조회
      try {
        final userDoc = await firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userData['id'] = user.uid;

          print('Firestore에서 사용자 정보 조회 성공');
          return UserModel.fromMap(userData);
        }
      } catch (e) {
        print('Firestore 조회 오류: $e');
        // Firestore 오류는 무시하고 기본 정보로 진행
      }

      // 4. Firestore 정보가 없는 경우 기본 UserModel 생성 및 반환
      print('기본 UserModel 생성');
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? email,
        name: user.displayName ?? email.split('@')[0],
        role: domain.UserEntityRole.student, // 기본값으로 학생 역할 설정
        createdAt: DateTime.now(),
      );

      print('로그인 성공: ${userModel.toString()}');
      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth 예외: ${e.code}, ${e.message}');
      throw AuthException(message: _getAuthErrorMessage(e.code), code: e.code);
    } catch (e) {
      print('로그인 중 예외 발생: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw ServerException(message: '로그인 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    domain.UserEntityRole role,
  ) async {
    try {
      final methods = await firebaseAuth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw ServerException(message: '이미 가입된 이메일입니다.');
      }

      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw ServerException(message: '계정 생성에 실패했습니다.');
      }

      final userId = firebaseUser.uid;
      final now = DateTime.now();

      final userModel = UserModel(
        id: userId,
        email: email,
        name: name,
        role: role,
        createdAt: now,
      );

      await firestore.collection('users').doc(userId).set(userModel.toMap());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _getAuthErrorMessage(e.code), code: e.code);
    } catch (e, stackTrace) {
      if (e is AuthException) {
        rethrow;
      }
      throw ServerException(
        message: '회원가입 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw AuthException(
        message: e.message ?? '로그아웃 중 오류가 발생했습니다.',
        code: e.code,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw ServerException(message: e.toString(), stackTrace: stackTrace);
    }
  }

  @override
  Future<UserModel> updateUserInfo(UserModel user) async {
    try {
      await firestore.collection('users').doc(user.id).update(user.toMap());
      return user;
    } catch (e, stackTrace) {
      throw ServerException(
        message: '사용자 정보 업데이트에 실패했습니다: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw ServerException(message: '사용자 정보를 찾을 수 없습니다.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      userData['id'] = userId;

      return UserModel.fromMap(userData);
    } catch (e) {
      throw ServerException(message: '사용자 정보 조회 오류: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, String imagePath) async {
    try {
      final file = File(imagePath);
      final storageRef = storage.ref().child('profileImages/$userId.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await firestore.collection('users').doc(userId).update({
        'profileImageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e, stackTrace) {
      throw ServerException(
        message: '프로필 이미지 업로드에 실패했습니다: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw AuthException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw ServerException(message: e.toString(), stackTrace: stackTrace);
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await firestore.collection('users').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      throw ServerException(
        message: '사용자 목록 조회 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<UserModel>> getUsersByRole(domain.UserEntityRole role) async {
    try {
      final querySnapshot =
          await firestore
              .collection('users')
              .where('role', isEqualTo: role.toString().split('.').last)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      throw ServerException(
        message: '${role.toString()} 역할 사용자 목록 조회 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot =
          await firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        throw NotFoundException(message: '이메일로 사용자를 찾을 수 없습니다: $email');
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;

      return UserModel.fromMap(data);
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        message: '이메일로 사용자 조회 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<String> createUser(UserModel user) async {
    try {
      final docRef = await firestore.collection('users').add(user.toMap());
      return docRef.id;
    } catch (e, stackTrace) {
      throw ServerException(
        message: '사용자 생성 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      final userDoc = await firestore.collection('users').doc(user.id).get();

      if (!userDoc.exists) {
        throw NotFoundException(message: '사용자를 찾을 수 없습니다: ${user.id}');
      }

      await firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        message: '사용자 업데이트 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw NotFoundException(message: '사용자를 찾을 수 없습니다: $userId');
      }

      await firestore.collection('users').doc(userId).delete();
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        message: '사용자 삭제 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> addClassToUser(String userId, String classId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw NotFoundException(message: '사용자를 찾을 수 없습니다: $userId');
      }

      await firestore.collection('users').doc(userId).update({
        'classes': FieldValue.arrayUnion([classId]),
      });
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        message: '사용자에게 강의 추가 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> removeClassFromUser(String userId, String classId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw NotFoundException(message: '사용자를 찾을 수 없습니다: $userId');
      }

      await firestore.collection('users').doc(userId).update({
        'classes': FieldValue.arrayRemove([classId]),
      });
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        message: '사용자에게서 강의 삭제 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<UserModel>> getStudentsByDepartment(String department) async {
    try {
      final querySnapshot =
          await firestore
              .collection('users')
              .where(
                'role',
                isEqualTo:
                    domain.UserEntityRole.student.toString().split('.').last,
              )
              .where('department', isEqualTo: department)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      throw ServerException(
        message: '$department 학과의 학생 목록 조회 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<UserModel>> getStudentsByClassId(String classId) async {
    try {
      final querySnapshot =
          await firestore
              .collection('users')
              .where(
                'role',
                isEqualTo:
                    domain.UserEntityRole.student.toString().split('.').last,
              )
              .where('classes', arrayContains: classId)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      throw ServerException(
        message: '$classId 강의를 수강 중인 학생 목록 조회 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> updateUserDeviceInfo(
    String userId,
    Map<String, dynamic> deviceInfo,
  ) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw NotFoundException(message: '사용자를 찾을 수 없습니다: $userId');
      }

      await firestore.collection('users').doc(userId).update({
        'deviceInfo': deviceInfo,
      });
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServerException(
        message: '사용자 기기 정보 업데이트 오류: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '인증 오류가 발생했습니다.';
    }
  }
}
