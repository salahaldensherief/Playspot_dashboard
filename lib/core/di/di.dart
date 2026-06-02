import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/data_source/auth_remote_data_source.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/login/login_cubit.dart';

final sl = GetIt.instance;

Future<void> setupInjection() async {
  await Supabase.initialize(
    url: 'https://tgpdexoitemmpruepgyt.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRncGRleG9pdGVtbXBydWVwZ3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NjYyNzYsImV4cCI6MjA5NDI0MjI3Nn0.i5ekdw4CkWh97-BGWzCRQZ4c9bIKWIo2vD-Ev58BVC4',
  );

  // Register Supabase Client
  sl.registerLazySingleton<SupabaseClient>(
        () => Supabase.instance.client,
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<LoginCubit>(
        () => LoginCubit(sl()),
  );
}