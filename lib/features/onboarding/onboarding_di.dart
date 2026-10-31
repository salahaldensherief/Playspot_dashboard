import 'package:get_it/get_it.dart';
import 'data/datasources/onboarding_remote_data_source.dart';
import 'data/datasources/onboarding_remote_data_source_impl.dart';
import 'data/repositories/onboarding_repository_impl.dart';
import 'domain/repositories/onboarding_repository.dart';
import 'domain/usecases/setup_lounge_usecase.dart';
import 'domain/usecases/batch_complete_onboarding_usecase.dart';
import 'domain/usecases/add_room_usecase.dart';
import 'domain/usecases/add_extra_usecase.dart';
import 'domain/usecases/get_saved_onboarding_draft_usecase.dart';
import 'presentation/cubit/onboarding_cubit.dart';

void initOnboardingDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SetupLoungeUseCase(sl()));
  sl.registerLazySingleton(() => BatchCompleteOnboardingUseCase(sl()));
  sl.registerLazySingleton(() => AddRoomUseCase(sl()));
  sl.registerLazySingleton(() => AddExtraUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedOnboardingDraftUseCase(sl()));

  // Cubits
  sl.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(
      addRoomUseCase: sl(),
      getSavedDraftUseCase: sl(),
      addExtraUseCase: sl(),
      batchCompleteOnboardingUseCase: sl(),
      locationService: sl(),
      localCacheService: sl(),
    ),
  );
}
