import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../entities/class.dart';
import '../entities/user.dart' as domain;
import '../../core/error/failures.dart';
import '../models/class_model.dart';

abstract class ClassRepository {
  /// 모든 수업 목록을 가져옵니다.
  Future<Either<Failure, List<Class>>> getAllClasses();

  /// 특정 교수의 수업 목록을 가져옵니다.
  Future<Either<Failure, List<Class>>> getClassesByProfessorId(
    String professorId,
  );

  /// 특정 학생이 등록된 수업 목록을 가져옵니다.
  Future<Either<Failure, List<Class>>> getClassesByStudentId(String studentId);

  /// 수업 ID로 특정 수업을 가져옵니다.
  Future<Either<Failure, Class?>> getClassById(String classId);

  /// 수업을 추가하거나 업데이트합니다.
  Future<Either<Failure, Class>> saveClass(Class classEntity);

  /// 수업 정보를 업데이트합니다.
  Future<Either<Failure, Class>> updateClass(Class classEntity);

  /// 수업에 학생을 추가합니다.
  Future<Either<Failure, Class>> addStudentToClass(
    String classId,
    String studentId,
  );

  /// 수업에서 학생을 제거합니다.
  Future<Either<Failure, Class>> removeStudentFromClass(
    String classId,
    String studentId,
  );

  /// 수업을 삭제합니다.
  Future<Either<Failure, void>> deleteClass(String classId);

  /// 특정 교수의 수업 목록을 가져옵니다.
  Future<Either<Failure, List<Class>>> getProfessorClasses(String professorId);

  /// 수업을 시작합니다.
  Future<Either<Failure, void>> startClass(String classId);

  /// 수업을 종료합니다.
  Future<Either<Failure, void>> endClass(String classId);

  /// 오늘 진행될 강의 목록을 가져옵니다. (요일 기준)
  Future<Either<Failure, List<Class>>> getTodayClasses(domain.User user);
}

/// 강의 정보 관리를 위한 Repository 구현 클래스
class ClassRepositoryImpl implements ClassRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'classes';

  ClassRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 모든 강의 목록을 가져옵니다.
  @override
  Future<Either<Failure, List<Class>>> getAllClasses() async {
    try {
      final snapshot =
          await _firestore.collection(_collectionPath).orderBy('name').get();

      final classes =
          snapshot.docs
              .map((doc) => _convertToClass(ClassModel.fromFirestore(doc)))
              .toList();

      return Right(classes);
    } catch (e) {
      debugPrint('모든 강의 목록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 특정 교수의 강의 목록을 가져옵니다.
  @override
  Future<Either<Failure, List<Class>>> getClassesByProfessorId(
    String professorId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('professorId', isEqualTo: professorId)
              .orderBy('name')
              .get();

      final classes =
          snapshot.docs
              .map((doc) => _convertToClass(ClassModel.fromFirestore(doc)))
              .toList();

      return Right(classes);
    } catch (e) {
      debugPrint('교수 강의 목록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 특정 학생이 수강 중인 강의 목록을 가져옵니다.
  @override
  Future<Either<Failure, List<Class>>> getClassesByStudentId(
    String studentId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('studentIds', arrayContains: studentId)
              .orderBy('name')
              .get();

      final classes =
          snapshot.docs
              .map((doc) => _convertToClass(ClassModel.fromFirestore(doc)))
              .toList();

      return Right(classes);
    } catch (e) {
      debugPrint('학생 강의 목록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// ID로 특정 강의를 가져옵니다.
  @override
  Future<Either<Failure, Class?>> getClassById(String classId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collectionPath).doc(classId).get();

      if (!docSnapshot.exists) {
        return const Right(null);
      }

      final classModel = ClassModel.fromFirestore(docSnapshot);
      final classEntity = _convertToClass(classModel);

      return Right(classEntity);
    } catch (e) {
      debugPrint('강의 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 수업을 추가하거나 업데이트합니다.
  @override
  Future<Either<Failure, Class>> saveClass(Class classEntity) async {
    try {
      final now = DateTime.now();
      // 클래스 모델로 변환
      final classModel = _convertToClassModel(classEntity);

      // 클래스 ID가 있는 경우 (업데이트)
      if (classEntity.id.isNotEmpty) {
        final docRef = _firestore
            .collection(_collectionPath)
            .doc(classEntity.id);

        // 업데이트 전 기존 문서 확인
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          debugPrint('기존 문서 업데이트: ${classEntity.id}');
          // 기존 문서에서 학생 ID 목록 확인
          final existingData = docSnapshot.data();
          List<String> existingStudentIds = [];

          if (existingData != null && existingData['studentIds'] != null) {
            existingStudentIds = List<String>.from(existingData['studentIds']);
            debugPrint('기존 문서의 학생 수: ${existingStudentIds.length}');
          }

          // 새 데이터와 기존 학생 ID 비교
          final newStudentIds = classModel.studentIds;
          debugPrint('새 데이터의 학생 수: ${newStudentIds.length}');

          // 새 데이터에 학생 ID가 없고 기존 데이터에 있는 경우 기존 것을 유지
          final finalStudentIds =
              newStudentIds.isEmpty && existingStudentIds.isNotEmpty
                  ? existingStudentIds
                  : newStudentIds;

          debugPrint('최종 업데이트할 학생 수: ${finalStudentIds.length}');

          // 학생 목록을 최종 값으로 업데이트
          final updatedModel = classModel.copyWith(studentIds: finalStudentIds);
          debugPrint('Firestore에 저장할 학생 ID 목록: ${updatedModel.studentIds}');

          // 업데이트 시간 설정
          final updateData = {
            ...updatedModel.toFirestore(),
            'updatedAt': Timestamp.fromDate(now),
          };

          // merge: true 옵션으로 기존 필드 유지하면서 업데이트
          await docRef.set(updateData, SetOptions(merge: true));
        } else {
          debugPrint('문서가 존재하지 않아 신규 생성: ${classEntity.id}');
          final updateData = {
            ...classModel.toFirestore(),
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          };
          await docRef.set(updateData);
        }

        // 업데이트된 클래스 정보 가져오기
        final result = await getClassById(classEntity.id);
        return result.fold(
          (failure) => Left(failure),
          (classData) =>
              classData != null
                  ? Right(classData)
                  : const Left(ServerFailure(message: '업데이트된 클래스를 찾을 수 없습니다.')),
        );
      } else {
        // 신규 클래스 (ID가 없는 경우)
        debugPrint('신규 클래스 생성 중');
        final docRef = _firestore.collection(_collectionPath).doc();
        // ID 할당 및 시간 필드 추가
        final newClassData = {
          ...classModel.toFirestore(),
          'id': docRef.id,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        };
        await docRef.set(newClassData);

        // 새로 생성된 클래스 정보 가져오기
        final result = await getClassById(docRef.id);
        return result.fold(
          (failure) => Left(failure),
          (classData) =>
              classData != null
                  ? Right(classData)
                  : const Left(ServerFailure(message: '생성된 클래스를 찾을 수 없습니다.')),
        );
      }
    } catch (e) {
      debugPrint('클래스 저장 중 오류 발생: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 수업 정보를 업데이트합니다.
  @override
  Future<Either<Failure, Class>> updateClass(Class classEntity) async {
    if (classEntity.id.isEmpty) {
      return const Left(ServerFailure(message: '유효하지 않은 수업 ID입니다.'));
    }
    // saveClass 메서드를 활용하여 업데이트 로직 구현
    return saveClass(classEntity);
  }

  /// 강의에 학생을 등록합니다.
  @override
  Future<Either<Failure, Class>> addStudentToClass(
    String classId,
    String studentId,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(classId).update({
        'studentIds': FieldValue.arrayUnion([studentId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final updatedClassResult = await getClassById(classId);

      return updatedClassResult.fold((failure) => Left(failure), (
        updatedClass,
      ) {
        if (updatedClass == null) {
          return const Left(ServerFailure(message: '강의를 찾을 수 없습니다.'));
        }
        return Right(updatedClass);
      });
    } catch (e) {
      debugPrint('학생 등록 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 강의에서 학생을 제외합니다.
  @override
  Future<Either<Failure, Class>> removeStudentFromClass(
    String classId,
    String studentId,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(classId).update({
        'studentIds': FieldValue.arrayRemove([studentId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final updatedClassResult = await getClassById(classId);

      return updatedClassResult.fold((failure) => Left(failure), (
        updatedClass,
      ) {
        if (updatedClass == null) {
          return const Left(ServerFailure(message: '강의를 찾을 수 없습니다.'));
        }
        return Right(updatedClass);
      });
    } catch (e) {
      debugPrint('학생 제외 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 강의를 삭제합니다.
  @override
  Future<Either<Failure, void>> deleteClass(String classId) async {
    try {
      await _firestore.collection(_collectionPath).doc(classId).delete();
      return const Right(null);
    } catch (e) {
      debugPrint('강의 삭제 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 여러 학생을 한 번에 강의에 등록합니다.
  Future<Either<Failure, void>> addMultipleStudentsToClass(
    String classId,
    List<String> studentIds,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(classId).update({
        'studentIds': FieldValue.arrayUnion(studentIds),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Right(null);
    } catch (e) {
      debugPrint('다수 학생 등록 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 오늘 진행될 강의 목록을 가져옵니다. (요일 기준)
  @override
  Future<Either<Failure, List<Class>>> getTodayClasses(domain.User user) async {
    try {
      final today = DateTime.now().weekday;
      final weekdayString = _getWeekdayString(today);

      // 사용자 역할에 따라 쿼리 구성
      Query query;
      if (user.role == domain.UserEntityRole.professor) {
        // 교수인 경우 담당 강의 조회
        query = _firestore
            .collection(_collectionPath)
            .where('professorId', isEqualTo: user.id);
      } else {
        // 학생인 경우 수강 중인 강의 조회
        query = _firestore
            .collection(_collectionPath)
            .where('studentIds', arrayContains: user.id);
      }

      final snapshot = await query.get();
      final allClasses =
          snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();

      // 스케줄에 오늘 요일이 포함된 강의만 필터링하여 Class 엔티티로 변환
      final todayClasses =
          allClasses
              .where((classModel) => _isClassToday(classModel))
              .map((classModel) => _convertToClass(classModel))
              .toList();

      return Right(todayClasses);
    } catch (e) {
      debugPrint('오늘의 강의 목록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// ClassModel을 Class 엔티티로 변환하는 도우미 함수
  Class _convertToClass(ClassModel model) {
    // 첫 번째 일정 정보를 기준으로 변환 (단순화를 위해)
    final firstSchedule =
        model.schedule.isNotEmpty
            ? model.schedule.first
            : {'day': '월', 'startTime': '09:00', 'endTime': '10:00'};

    return Class(
      id: model.id,
      name: model.name,
      professorId: model.professorId,
      location: model.location,
      weekDay: _parseWeekDay(firstSchedule['day'] ?? '월'),
      startTime: firstSchedule['startTime'] ?? '09:00',
      endTime: firstSchedule['endTime'] ?? '10:00',
      status: ClassStatus.scheduled, // 기본값 사용
      studentIds: model.studentIds,
      createdAt: model.createdAt,
      lastUpdatedAt: model.updatedAt,
    );
  }

  /// Class 엔티티를 ClassModel로 변환하는 도우미 함수
  ClassModel _convertToClassModel(Class classEntity) {
    final schedule = [
      {
        'day': _getWeekDayString(classEntity.weekDay),
        'startTime': classEntity.startTime,
        'endTime': classEntity.endTime,
      },
    ];

    // studentIds 배열이 제대로 변환되는지 디버깅
    final studentIds = classEntity.studentIds;
    debugPrint('_convertToClassModel - 입력 studentIds: $studentIds');

    final result = ClassModel(
      id: classEntity.id,
      name: classEntity.name,
      professorId: classEntity.professorId,
      professorName: '', // 정보가 없으므로 빈 문자열로 설정
      location: classEntity.location ?? '',
      description: '', // 정보가 없으므로 빈 문자열로 설정
      schedule: schedule,
      studentIds: List<String>.from(studentIds), // 배열 복사본 생성하여 할당
      createdAt: classEntity.createdAt,
      updatedAt: classEntity.lastUpdatedAt ?? classEntity.createdAt,
    );

    debugPrint('_convertToClassModel - 결과 studentIds: ${result.studentIds}');
    return result;
  }

  /// 문자열에서 WeekDay로 변환하는 도우미 함수
  WeekDay _parseWeekDay(String dayStr) {
    switch (dayStr) {
      case '월':
        return WeekDay.monday;
      case '화':
        return WeekDay.tuesday;
      case '수':
        return WeekDay.wednesday;
      case '목':
        return WeekDay.thursday;
      case '금':
        return WeekDay.friday;
      case '토':
        return WeekDay.saturday;
      case '일':
        return WeekDay.sunday;
      default:
        return WeekDay.monday;
    }
  }

  /// WeekDay에서 문자열로 변환하는 도우미 함수
  String _getWeekDayString(WeekDay weekDay) {
    switch (weekDay) {
      case WeekDay.monday:
        return '월';
      case WeekDay.tuesday:
        return '화';
      case WeekDay.wednesday:
        return '수';
      case WeekDay.thursday:
        return '목';
      case WeekDay.friday:
        return '금';
      case WeekDay.saturday:
        return '토';
      case WeekDay.sunday:
        return '일';
    }
  }

  /// 주중 파싱 (1: 월요일, ..., 7: 일요일)
  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  /// 오늘 강의인지 확인
  bool _isClassToday(ClassModel classModel) {
    final today = DateTime.now().weekday;
    final weekdayString = _getWeekdayString(today);
    return classModel.schedule.any(
      (schedule) => schedule['day'] == weekdayString,
    );
  }

  /// 특정 교수의 수업 목록을 가져옵니다.
  @override
  Future<Either<Failure, List<Class>>> getProfessorClasses(
    String professorId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('professorId', isEqualTo: professorId)
              .orderBy('name')
              .get();

      final classes =
          snapshot.docs
              .map((doc) => _convertToClass(ClassModel.fromFirestore(doc)))
              .toList();

      return Right(classes);
    } catch (e) {
      debugPrint('교수 강의 목록 조회 실패: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// 수업을 시작합니다.
  @override
  Future<Either<Failure, void>> startClass(String classId) async {
    // Implementation needed
    return const Left(ServerFailure(message: 'Method not implemented'));
  }

  /// 수업을 종료합니다.
  @override
  Future<Either<Failure, void>> endClass(String classId) async {
    // Implementation needed
    return const Left(ServerFailure(message: 'Method not implemented'));
  }
}
