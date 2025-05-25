import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/network/network_info.dart';
import '../core/theme/theme_provider.dart';
import '../data/datasources/user_remote_data_source.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/sign_in_with_email_password.dart';
import '../domain/usecases/sign_up_with_email_password.dart';
import '../presentation/providers/auth_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Provider
  sl.registerFactory(
    () => AuthProvider(getCurrentUser: sl(), signIn: sl(), signUp: sl()),
  );

  // Theme Provider
  sl.registerLazySingleton(() => ThemeProvider());

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignInWithEmailPassword(sl()));
  sl.registerLazySingleton(() => SignUpWithEmailPassword(sl()));

  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      storage: sl(),
    ),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker(),
  );
}
