import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_with_email_password.dart';
import '../../domain/usecases/sign_up_with_email_password.dart';
import '../../core/usecases/usecase.dart';
import '../../data/models/user_model.dart';

/// 인증 상태를 나타내는 열거형
enum AuthStatus {
  initial, // 초기 상태
  authenticated, // 인증됨
  unauthenticated, // 인증되지 않음
  loading, // 로딩 중
  error, // 오류 발생
}

/// 인증 상태를 관리하는 Provider 클래스
class AuthProvider with ChangeNotifier {
  final GetCurrentUser? _getCurrentUser;
  final SignInWithEmailPassword? _signIn;
  final SignUpWithEmailPassword? _signUp;

  User? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  String _errorMessage = '';

  /// 생성자
  AuthProvider({
    GetCurrentUser? getCurrentUser,
    SignInWithEmailPassword? signIn,
    SignUpWithEmailPassword? signUp,
  }) : _getCurrentUser = getCurrentUser,
       _signIn = signIn,
       _signUp = signUp;

  /// 현재 인증된 사용자 getter
  User? get currentUser => _currentUser;

  /// 현재 인증 상태 getter
  AuthStatus get status => _status;

  /// 로딩 상태 getter
  bool get isLoading => _isLoading;

  /// 오류 메시지 getter
  String get errorMessage => _errorMessage;

  /// 초기화 메서드
  Future<void> init() async {
    print('AuthProvider: 초기화 시작');
    _status = AuthStatus.loading;
    _isLoading = true;
    notifyListeners();

    try {
      if (_getCurrentUser == null) {
        print('_getCurrentUser 유즈케이스가 null입니다. 임시 로직을 사용합니다.');
        // 유즈케이스가 주입되지 않은 경우 임시 로직 사용
        await Future.delayed(const Duration(milliseconds: 500)); // 비동기 작업 시뮬레이션

        // 테스트용: 인증되지 않은 상태로 설정
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('AuthProvider: _getCurrentUser 호출');
      final result = await _getCurrentUser(NoParams());
      print('AuthProvider: _getCurrentUser 결과 받음');

      result.fold(
        (failure) {
          print('AuthProvider: 현재 사용자 가져오기 실패 - ${failure.message}');
          _status = AuthStatus.unauthenticated;
          _isLoading = false;
          notifyListeners();
        },
        (user) {
          if (user != null) {
            print('AuthProvider: 인증된 사용자 발견 - 사용자 ID: ${user.id}');
            _currentUser = user;
            _status = AuthStatus.authenticated;
          } else {
            print('AuthProvider: 인증된 사용자 없음');
            _status = AuthStatus.unauthenticated;
          }
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('AuthProvider: 예외 발생 - $e');
      _status = AuthStatus.error;
      _errorMessage = '인증 상태 확인 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 이메일과 비밀번호를 사용하여 회원가입
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserEntityRole role,
  }) async {
    _setLoading(true);
    try {
      if (_signUp == null) {
        print('_signUp 유즈케이스가 null입니다. 대체 회원가입 로직을 사용합니다.');
        // 임시 구현: 직접 Firebase Auth와 Firestore를 사용하여 회원가입 처리
        try {
          // Firebase Auth를 직접 사용하여 회원가입
          final firebaseAuth = firebase_auth.FirebaseAuth.instance;
          final firestore = FirebaseFirestore.instance;

          // 사용자 생성
          final userCredential = await firebaseAuth
              .createUserWithEmailAndPassword(email: email, password: password);

          if (userCredential.user != null) {
            final userId = userCredential.user!.uid;

            // Firestore에 사용자 정보 저장
            await firestore.collection('users').doc(userId).set({
              'id': userId,
              'email': email,
              'name': name,
              'role': role.toString().split('.').last,
              'createdAt': DateTime.now().toIso8601String(),
            });

            // 사용자 표시 이름 설정
            await userCredential.user!.updateDisplayName(name);

            // 현재 사용자 정보 업데이트
            _currentUser = UserModel(
              id: userId,
              email: email,
              name: name,
              role: role,
              createdAt: DateTime.now(),
            );

            _status = AuthStatus.authenticated;
            _isLoading = false;
            notifyListeners();
            return;
          }
        } catch (e) {
          _setError('회원가입 중 오류 발생: $e');
          return;
        }
      } else {
        final result = await _signUp(
          SignUpParams(
            email: email,
            password: password,
            name: name,
            role: role,
          ),
        );

        result.fold((failure) => _setError(failure.message), (_) {
          _setLoading(false);
          notifyListeners();
        });
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 이메일과 비밀번호로 로그인
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    print('AuthProvider: 로그인 시작');
    _status = AuthStatus.loading;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (_signIn == null) {
        print('_signIn 유즈케이스가 null입니다. 임시 로그인 로직을 사용합니다.');
        // 유즈케이스가 주입되지 않은 경우 임시 로직 사용
        await Future.delayed(const Duration(milliseconds: 500)); // 비동기 작업 시뮬레이션

        // 테스트용 사용자 데이터 설정
        UserEntityRole role =
            email.contains('professor')
                ? UserEntityRole.professor
                : UserEntityRole.student;
        print('AuthProvider: 테스트 데이터 사용 - 이메일: $email, 역할: $role');

        _currentUser = UserModel(
          id: 'test-user-id',
          email: email,
          name: email.contains('professor') ? '테스트 교수' : '테스트 학생',
          role: role,
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final params = SignInParams(email: email, password: password);
      print('AuthProvider: _signIn 호출');
      final result = await _signIn(params);
      print('AuthProvider: _signIn 결과 받음');

      return result.fold(
        (failure) {
          print('AuthProvider: 로그인 실패 - ${failure.message}');
          _status = AuthStatus.error;
          _errorMessage = '로그인에 실패했습니다. 이메일 또는 비밀번호를 확인해주세요.';
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (user) {
          print(
            'AuthProvider: 로그인 성공 - 사용자 ID: ${user.id}, 역할: ${user.role}, 교수여부: ${user.isProfessor}',
          );
          _currentUser = user;
          _status = AuthStatus.authenticated;
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      print('AuthProvider: 예외 발생 - $e');
      _status = AuthStatus.error;
      _errorMessage = '로그인 처리 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
}
