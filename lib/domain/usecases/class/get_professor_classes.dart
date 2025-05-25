import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/class.dart';
import '../../repositories/class_repository.dart';

/// 교수의 수업 목록을 조회하는 유스케이스
class GetProfessorClasses {
  final ClassRepository _repository;

  GetProfessorClasses(this._repository);

  /// 교수 수업 목록 조회 실행
  /// @param professorId 교수 ID
  /// @return 수업 엔티티 목록 또는 실패
  Future<Either<Failure, List<Class>>> call(String professorId) async {
    return await _repository.getClassesByProfessorId(professorId);
  }
}
