import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';
import '../../data/models/user_model.dart' show UserModel;

class SignUpWithEmailPassword implements UseCase<User, SignUpParams> {
  final UserRepository repository;

  SignUpWithEmailPassword(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpParams params) {
    return repository.signUpWithEmailAndPassword(
      params.email,
      params.password,
      params.name,
      params.role,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final UserEntityRole role;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  @override
  List<Object> get props => [email, password, name, role];
}
