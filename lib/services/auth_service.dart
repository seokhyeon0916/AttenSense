import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 사용자 가져오기
  firebase_auth.User? get currentUser => _auth.currentUser;

  // 사용자 인증 상태 변경 리스너
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // 이메일/비밀번호로 회원가입
  Future<firebase_auth.UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserEntityRole role,
  }) async {
    try {
      // 사용자 생성
      final firebase_auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 추가 사용자 정보 저장
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'role': role.toString().split('.').last,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 사용자 표시 이름 설정
        await userCredential.user!.updateDisplayName(name);
      }

      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 이메일/비밀번호로 로그인
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 사용자 역할 가져오기
  Future<UserEntityRole?> getUserRole() async {
    if (currentUser == null) return null;

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String roleStr = data['role'] as String;

        return roleStr == 'professor'
            ? UserEntityRole.professor
            : UserEntityRole.student;
      }

      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // 예외 처리
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('사용자를 찾을 수 없습니다.');
      case 'wrong-password':
        return Exception('비밀번호가 올바르지 않습니다.');
      case 'email-already-in-use':
        return Exception('이미 사용 중인 이메일입니다.');
      case 'weak-password':
        return Exception('비밀번호가 너무 약합니다.');
      case 'invalid-email':
        return Exception('유효하지 않은 이메일 형식입니다.');
      default:
        return Exception('인증 오류: ${e.message}');
    }
  }
}
