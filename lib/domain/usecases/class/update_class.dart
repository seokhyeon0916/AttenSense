import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/class.dart';
import '../../repositories/class_repository.dart';

/// 수업을 업데이트하는 유스케이스
class UpdateClass {
  final ClassRepository _repository;

  UpdateClass(this._repository);

  /// 수업 업데이트 실행
  /// @param classEntity 업데이트할 수업 엔티티
  /// @return 업데이트된 수업 엔티티 또는 실패
  Future<Either<Failure, Class>> call(Class classEntity) async {
    return await _repository.saveClass(classEntity);
  }
}
