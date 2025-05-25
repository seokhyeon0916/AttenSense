import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/class_repository.dart';

/// 수업을 종료하는 유스케이스
class EndClass {
  final ClassRepository _repository;

  EndClass(this._repository);

  /// 수업 종료 실행
  /// @param classId 종료할 수업 ID
  /// @return 성공 여부 또는 실패
  Future<Either<Failure, void>> call(String classId) async {
    return await _repository.endClass(classId);
  }
}
