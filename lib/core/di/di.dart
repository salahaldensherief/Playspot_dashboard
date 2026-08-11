import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:play_spot_dashboard/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:play_spot_dashboard/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_spot_dashboard/features/auth/domain/repositories/auth_repository.dart';
import 'package:play_spot_dashboard/features/auth/domain/usecases/login_usecase.dart';
import 'package:play_spot_dashboard/features/auth/domain/usecases/logout_usecase.dart';
import 'package:play_spot_dashboard/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_realtime_datasource.dart';
import 'package:play_spot_dashboard/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/watch_bookings.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/update_booking_status.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/confirm_cash_payment.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounges/data/repositories/lounge_repository_impl.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/rooms/data/datasources/room_remote_data_source.dart';
import 'package:play_spot_dashboard/features/rooms/data/repositories/room_repository_impl.dart';
import 'package:play_spot_dashboard/features/rooms/domain/repositories/room_repository.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:play_spot_dashboard/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/setup_lounge_usecase.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/add_room_usecase.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/usecases/add_extra_usecase.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:play_spot_dashboard/features/users/data/datasources/admin_management_remote_data_source.dart';
import 'package:play_spot_dashboard/features/users/data/repositories/admin_management_repository_impl.dart';
import 'package:play_spot_dashboard/features/users/domain/repositories/admin_management_repository.dart';
import 'package:play_spot_dashboard/features/users/domain/usecases/create_lounge_admin_usecase.dart';
import 'package:play_spot_dashboard/features/users/domain/usecases/get_admins_usecase.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/admin_management_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';

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
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(sl()));

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
  sl.registerLazySingleton<RoomRemoteDataSource>(
    () => RoomRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AdminManagementRemoteDataSource>(
    () => AdminManagementRemoteDataSourceImpl(sl()),
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
  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AdminManagementRepository>(
    () => AdminManagementRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  
  sl.registerLazySingleton(() => WatchBookings(sl()));
  sl.registerLazySingleton(() => UpdateBookingStatus(sl()));
  sl.registerLazySingleton(() => ConfirmCashPayment(sl()));
  sl.registerLazySingleton(() => SetupLoungeUseCase(sl()));
  sl.registerLazySingleton(() => AddRoomUseCase(sl()));
  sl.registerLazySingleton(() => AddExtraUseCase(sl()));
  sl.registerLazySingleton(() => CreateLoungeAdminUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminsUseCase(sl()));

  // Cubits
  sl.registerFactory<LoginCubit>(
        () => LoginCubit(
          loginUseCase: sl(),
          logoutUseCase: sl(),
          getCurrentUserUseCase: sl(),
          loungeRepository: sl(),
        ),
  );
  sl.registerFactory<BookingCubit>(
    () => BookingCubit(
      watchBookings: sl(),
      updateBookingStatus: sl(),
      confirmCashPaymentUseCase: sl(),
    ),
  );
  sl.registerFactory<LoungeCubit>(
    () => LoungeCubit(sl()),
  );
  sl.registerFactory<ExtrasCubit>(
    () => ExtrasCubit(sl()),
  );
  sl.registerFactory<DashboardCubit>(
    () => DashboardCubit(sl()),
  );
  sl.registerFactory<RoomCubit>(
    () => RoomCubit(sl()),
  );
  sl.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(
      addRoomUseCase: sl(),
      addExtraUseCase: sl(),
      setupLoungeUseCase: sl(),
    ),
  );
  sl.registerFactory<AdminManagementCubit>(
    () => AdminManagementCubit(
      createLoungeAdminUseCase: sl(),
      getAdminsUseCase: sl(),
    ),
  );
}
