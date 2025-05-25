import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/class.dart';
import '../../repositories/class_repository.dart';

/// 수업을 생성하는 유스케이스
class CreateClass {
  final ClassRepository _repository;

  CreateClass(this._repository);

  /// 수업 생성 실행
  /// @param classEntity 생성할 수업 엔티티
  /// @return 생성된 수업 엔티티 또는 실패
  Future<Either<Failure, Class>> call(Class classEntity) async {
    return await _repository.saveClass(classEntity);
  }
}
