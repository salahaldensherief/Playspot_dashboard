import 'data/datasources/cashier_conflict_data_source.dart';
import 'data/repositories/cashier_conflict_repository_impl.dart';
import 'domain/repositories/cashier_conflict_repository.dart';
import 'presentation/cashier_conflict_cubit.dart';
import 'domain/repositories/cashier_workspace_store.dart';
import 'data/datasources/cashier_workspace_store_impl.dart';
import 'presentation/offline_workspace_cubit.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/play_spot_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'data/datasources/offline_key_vault.dart';
import 'data/datasources/secure_offline_key_vault.dart';
import 'data/datasources/cashier_device_preferences.dart';
import 'data/datasources/cashier_store_factory.dart';
import 'data/datasources/cashier_store_factory_impl.dart';

Future<void> initOfflineCashierDI(GetIt sl) async {
  if (!kIsWeb) {
    final directory = await getApplicationSupportDirectory();
    Hive.init('${directory.path}/offline_cashier');
  }
  await GetStorage.init('playspot_device_preferences');
  sl.registerLazySingleton<OfflineKeyVault>(
    () => const SecureOfflineKeyVault(PlaySpotSecureStorage.instance),
  );
  sl.registerLazySingleton<CashierDevicePreferences>(
    () => CashierDevicePreferences(GetStorage('playspot_device_preferences')),
  );
  sl.registerLazySingleton<CashierConflictDataSource>(
    () => CashierConflictDataSource(sl()),
  );
  sl.registerLazySingleton<CashierConflictRepository>(
    () => CashierConflictRepositoryImpl(sl()),
  );
  sl.registerFactory<CashierConflictCubit>(() => CashierConflictCubit(sl()));
  sl.registerFactory<OfflineWorkspaceCubit>(() => OfflineWorkspaceCubit(sl()));
  sl.registerLazySingleton<CashierWorkspaceStore>(
    () => CashierWorkspaceStoreImpl(sl(), sl()),
  );
  sl.registerLazySingleton<CashierStoreFactory>(
    () => CashierStoreFactoryImpl(keys: sl(), client: sl()),
    dispose: (factory) => factory.dispose(),
  );
}
