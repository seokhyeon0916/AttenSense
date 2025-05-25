import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class SignInWithEmailPassword implements UseCase<User, SignInParams> {
  final UserRepository repository;

  SignInWithEmailPassword(this.repository);

  @override
  Future<Either<Failure, User>> call(SignInParams params) {
    print('SignInWithEmailPassword usecase 호출됨: 이메일=${params.email}');
    return repository.signInWithEmailAndPassword(params.email, params.password);
  }
}

class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
