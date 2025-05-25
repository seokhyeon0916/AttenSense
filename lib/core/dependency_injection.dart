import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/theme_provider.dart';
import '../domain/usecases/sign_up_with_email_password.dart';
import '../domain/usecases/sign_in_with_email_password.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/class_repository.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/datasources/user_remote_data_source.dart';
import '../data/datasources/user_remote_data_source_impl.dart'
    as remote_data_source_impl;
import '../services/attendance_statistics_service.dart';
import '../services/student_attendance_statistics_service.dart';
import 'network/network_info.dart';

// 싱글톤으로 사용할 서비스 로케이터 인스턴스
final sl = GetIt.instance;

// 의존성 주입 초기화 함수
Future<void> init() async {
  try {
    print('의존성 주입 초기화 시작...');

    // 외부 서비스 등록
    print('Firebase 서비스 등록 중...');
    sl.registerLazySingleton(() => firebase_auth.FirebaseAuth.instance);
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
    sl.registerLazySingleton(() => FirebaseStorage.instance);
    sl.registerLazySingleton(() => InternetConnectionChecker());
    print('Firebase 서비스 등록 완료');

    // 네트워크 정보 등록
    print('NetworkInfo 등록 중...');
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
    print('NetworkInfo 등록 완료');

    // 데이터 소스 등록
    if (!sl.isRegistered<UserRemoteDataSource>()) {
      print('UserRemoteDataSource 등록 중...');
      sl.registerLazySingleton<UserRemoteDataSource>(
        () => remote_data_source_impl.UserRemoteDataSourceImpl(
          firebaseAuth: sl<firebase_auth.FirebaseAuth>(),
          firestore: sl<FirebaseFirestore>(),
          storage: sl<FirebaseStorage>(),
        ),
      );
      print('UserRemoteDataSource 등록 완료');
    }

    // 레포지토리 등록
    if (!sl.isRegistered<UserRepository>()) {
      print('UserRepository 등록 중...');
      sl.registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
      );
      print('UserRepository 등록 완료');
    }

    // ClassRepository 등록
    if (!sl.isRegistered<ClassRepository>()) {
      print('ClassRepository 등록 중...');
      sl.registerLazySingleton<ClassRepository>(
        () => ClassRepositoryImpl(firestore: sl()),
      );
      print('ClassRepository 등록 완료');
    }

    // AttendanceStatisticsService 등록
    if (!sl.isRegistered<AttendanceStatisticsService>()) {
      print('AttendanceStatisticsService 등록 중...');
      sl.registerLazySingleton<AttendanceStatisticsService>(
        () => AttendanceStatisticsService(),
      );
      print('AttendanceStatisticsService 등록 완료');
    }

    // StudentAttendanceStatisticsService 등록
    if (!sl.isRegistered<StudentAttendanceStatisticsService>()) {
      print('StudentAttendanceStatisticsService 등록 중...');
      sl.registerLazySingleton<StudentAttendanceStatisticsService>(
        () => StudentAttendanceStatisticsService(),
      );
      print('StudentAttendanceStatisticsService 등록 완료');
    }

    // 유즈케이스 등록
    if (!sl.isRegistered<SignUpWithEmailPassword>()) {
      print('SignUpWithEmailPassword 등록 중...');
      sl.registerLazySingleton(() => SignUpWithEmailPassword(sl()));
      print('SignUpWithEmailPassword 등록 완료');
    }

    if (!sl.isRegistered<SignInWithEmailPassword>()) {
      print('SignInWithEmailPassword 등록 중...');
      sl.registerLazySingleton(() => SignInWithEmailPassword(sl()));
      print('SignInWithEmailPassword 등록 완료');
    }

    if (!sl.isRegistered<GetCurrentUser>()) {
      print('GetCurrentUser 등록 중...');
      sl.registerLazySingleton(() => GetCurrentUser(sl()));
      print('GetCurrentUser 등록 완료');
    }

    // 프로바이더 등록
    if (!sl.isRegistered<AuthProvider>()) {
      print('AuthProvider 등록 중...');
      sl.registerLazySingleton<AuthProvider>(
        () => AuthProvider(
          getCurrentUser: sl<GetCurrentUser>(),
          signIn: sl<SignInWithEmailPassword>(),
          signUp: sl<SignUpWithEmailPassword>(),
        ),
      );
      print('AuthProvider 등록 완료');
    } else {
      print('AuthProvider가 이미 등록되어 있습니다.');
    }

    if (!sl.isRegistered<ThemeProvider>()) {
      print('ThemeProvider 등록 중...');
      sl.registerLazySingleton<ThemeProvider>(() => ThemeProvider());
      print('ThemeProvider 등록 완료');
    } else {
      print('ThemeProvider가 이미 등록되어 있습니다.');
    }

    print('의존성 주입 초기화 완료');
  } catch (e) {
    print('의존성 주입 초기화 중 오류 발생: $e');
    // 오류가 발생했더라도 앱이 시작될 수 있도록 함
    if (!sl.isRegistered<AuthProvider>()) {
      print('오류 후 AuthProvider 직접 등록');
      sl.registerSingleton<AuthProvider>(AuthProvider());
    }

    if (!sl.isRegistered<ThemeProvider>()) {
      print('오류 후 ThemeProvider 직접 등록');
      sl.registerSingleton<ThemeProvider>(ThemeProvider());
    }

    // 오류 후 ClassRepository 직접 등록
    if (!sl.isRegistered<ClassRepository>()) {
      print('오류 후 ClassRepository 직접 등록');
      sl.registerSingleton<ClassRepository>(
        ClassRepositoryImpl(firestore: FirebaseFirestore.instance),
      );
    }

    // 오류 후 AttendanceStatisticsService 직접 등록
    if (!sl.isRegistered<AttendanceStatisticsService>()) {
      print('오류 후 AttendanceStatisticsService 직접 등록');
      sl.registerSingleton<AttendanceStatisticsService>(
        AttendanceStatisticsService(),
      );
    }

    // 오류 후 StudentAttendanceStatisticsService 직접 등록
    if (!sl.isRegistered<StudentAttendanceStatisticsService>()) {
      print('오류 후 StudentAttendanceStatisticsService 직접 등록');
      sl.registerSingleton<StudentAttendanceStatisticsService>(
        StudentAttendanceStatisticsService(),
      );
    }
  }
}
