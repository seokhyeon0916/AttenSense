import 'package:dartz/dartz.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/network_info.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.getCurrentUser();
        return Right(userModel);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message, stackTrace: e.stackTrace));
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.signInWithEmailAndPassword(
          email,
          password,
        );
        return Right(userModel);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message, stackTrace: e.stackTrace));
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserEntityRole role,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.signUpWithEmailAndPassword(
          email,
          password,
          name,
          role,
        );
        return Right(userModel);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message, stackTrace: e.stackTrace));
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signOut();
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message, stackTrace: e.stackTrace));
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> updateUserInfo(User user) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = UserModel.fromEntity(user);

        final updatedUserModel = await remoteDataSource.updateUserInfo(
          userModel,
        );
        return Right(updatedUserModel);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getUserById(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.getUserById(userId);
        return Right(userModel);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage(
    String userId,
    String imagePath,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final downloadUrl = await remoteDataSource.uploadProfileImage(
          userId,
          imagePath,
        );
        return Right(downloadUrl);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendPasswordResetEmail(email);
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message, stackTrace: e.stackTrace));
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getAllUsers() async {
    if (await networkInfo.isConnected) {
      try {
        final users = await remoteDataSource.getAllUsers();
        return Right(users);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getUsersByRole(
    UserEntityRole role,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final users = await remoteDataSource.getUsersByRole(role);
        return Right(users);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getUserByEmail(String email) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getUserByEmail(email);
        return Right(user);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> createUser(UserModel user) async {
    if (await networkInfo.isConnected) {
      try {
        final userId = await remoteDataSource.createUser(user);
        return Right(userId);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(UserModel user) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateUser(user);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteUser(userId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addClassToUser(
    String userId,
    String classId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addClassToUser(userId, classId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeClassFromUser(
    String userId,
    String classId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.removeClassFromUser(userId, classId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getStudentsByDepartment(
    String department,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final students = await remoteDataSource.getStudentsByDepartment(
          department,
        );
        return Right(students);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getStudentsByClassId(
    String classId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final students = await remoteDataSource.getStudentsByClassId(classId);
        return Right(students);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateUserDeviceInfo(
    String userId,
    Map<String, dynamic> deviceInfo,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateUserDeviceInfo(userId, deviceInfo);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, stackTrace: e.stackTrace),
        );
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message, stackTrace: e.stackTrace),
        );
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
