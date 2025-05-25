import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:capston_design/services/auth_service.dart';
import 'package:capston_design/domain/entities/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  firebase_auth.User? _user;
  UserEntityRole? _userRole;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _init();
  }

  firebase_auth.User? get user => _user;
  UserEntityRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isProfessor => _userRole == UserEntityRole.professor;
  bool get isStudent => _userRole == UserEntityRole.student;

  Future<void> _init() async {
    _setLoading(true);

    // 인증 상태 변경 리스너 설정
    _authService.authStateChanges.listen((firebase_auth.User? user) async {
      _user = user;

      if (user != null) {
        _userRole = await _authService.getUserRole();
      } else {
        _userRole = null;
      }

      notifyListeners();
    });

    _setLoading(false);
  }

  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserEntityRole role,
  }) async {
    _resetError();
    _setLoading(true);

    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _resetError();
    _setLoading(true);

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _resetError();
    _setLoading(true);

    try {
      await _authService.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    _resetError();
    _setLoading(true);

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _resetError() {
    _error = null;
    notifyListeners();
  }
}
