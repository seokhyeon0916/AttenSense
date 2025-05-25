import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// 모든 유스케이스가 구현해야 하는 추상 인터페이스
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// 파라미터가 필요 없는 유스케이스에 사용되는 클래스
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
