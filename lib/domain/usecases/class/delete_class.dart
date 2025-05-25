import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/class_repository.dart';

/// 수업을 삭제하는 유스케이스
class DeleteClass {
  final ClassRepository _repository;

  DeleteClass(this._repository);

  /// 수업 삭제 실행
  /// @param classId 삭제할 수업 ID
  /// @return 성공 여부 또는 실패
  Future<Either<Failure, void>> call(String classId) async {
    return await _repository.deleteClass(classId);
  }
}
