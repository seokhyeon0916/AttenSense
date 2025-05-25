import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/class_repository.dart';

/// 수업을 시작하는 유스케이스
class StartClass {
  final ClassRepository _repository;

  StartClass(this._repository);

  /// 수업 시작 실행
  /// @param classId 시작할 수업 ID
  /// @return 성공 여부 또는 실패
  Future<Either<Failure, void>> call(String classId) async {
    return await _repository.startClass(classId);
  }
}
