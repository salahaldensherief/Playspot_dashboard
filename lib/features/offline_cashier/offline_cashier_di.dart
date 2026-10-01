import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    () => const SecureOfflineKeyVault(FlutterSecureStorage()),
  );
  sl.registerLazySingleton<CashierDevicePreferences>(
    () => CashierDevicePreferences(GetStorage('playspot_device_preferences')),
  );
  sl.registerLazySingleton<CashierStoreFactory>(
    () => CashierStoreFactoryImpl(keys: sl(), client: sl()),
  );
}
