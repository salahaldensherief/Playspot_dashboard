import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:play_spot_dashboard/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:play_spot_dashboard/features/auth/domain/repositories/auth_repository.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/data/datasources/booking_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/data/datasources/booking_realtime_datasource.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/data/repositories/booking_repository_impl.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/domain/usecases/watch_bookings.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/domain/usecases/update_booking_status.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/data/repositories/lounge_repository_impl.dart';
import 'package:play_spot_dashboard/features/super_admin/lounge_management/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';

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

  // Core
  sl.registerLazySingleton<AudioService>(() => AudioServiceImpl());

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BookingRealtimeDataSource>(
    () => BookingRealtimeDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<LoungeRemoteDataSource>(
    () => LoungeRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<LoungeRepository>(
    () => LoungeRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => WatchBookings(sl()));
  sl.registerLazySingleton(() => UpdateBookingStatus(sl()));

  // Cubits
  sl.registerFactory<LoginCubit>(
        () => LoginCubit(sl()),
  );
  sl.registerFactory<BookingCubit>(
    () => BookingCubit(
      watchBookings: sl(),
      updateBookingStatus: sl(),
    ),
  );
  sl.registerFactory<LoungeCubit>(
    () => LoungeCubit(sl()),
  );
}
