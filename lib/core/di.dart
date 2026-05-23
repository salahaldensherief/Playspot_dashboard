import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/data/repos/auth_repository_impl.dart';
import '../features/auth/data/data_source/auth_remote_data_source.dart';
import '../features/auth/presetation/domain/auth_repository.dart';
import '../features/auth/presetation/login/login_cubit.dart';

final sl = GetIt.instance;

Future<void> setupInjection() async {
  // Features - Auth
  // Cubit
  sl.registerFactory(() => LoginCubit(sl()));
  
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // External
  sl.registerLazySingleton(() => Supabase.instance.client);
}
