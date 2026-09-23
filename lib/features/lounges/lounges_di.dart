import 'package:get_it/get_it.dart';
import 'data/datasources/lounge_remote_data_source.dart';
import 'data/datasources/lounge_remote_data_source_impl.dart';
import 'data/repositories/lounge_repository_impl.dart';
import 'data/repositories/lounge_payment_settings_repository_impl.dart';
import 'domain/repositories/lounge_repository.dart';
import 'domain/repositories/lounge_payment_settings_repository.dart';
import 'presentation/cubit/lounge_cubit.dart';
import 'presentation/cubit/extras_cubit.dart';
import 'presentation/cubit/lounge_payment_settings_cubit.dart';

void initLoungesDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<LoungeRemoteDataSource>(
    () => LoungeRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<LoungeRepository>(
    () => LoungeRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<LoungePaymentSettingsRepository>(
    () => LoungePaymentSettingsRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<LoungeCubit>(
    () => LoungeCubit(sl()),
  );
  sl.registerFactory<ExtrasCubit>(
    () => ExtrasCubit(sl()),
  );
  sl.registerFactory<LoungePaymentSettingsCubit>(
    () => LoungePaymentSettingsCubit(sl()),
  );
}
