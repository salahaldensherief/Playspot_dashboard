import 'package:get_it/get_it.dart';
import 'data/datasources/canteen_remote_datasource.dart';
import 'data/datasources/canteen_remote_datasource_impl.dart';
import 'data/repositories/canteen_repository_impl.dart';
import 'domain/repositories/canteen_repository.dart';
import 'domain/usecases/delete_combo_usecase.dart';
import 'domain/usecases/delete_upsell_rule_usecase.dart';
import 'domain/usecases/get_combos_usecase.dart';
import 'domain/usecases/get_low_stock_alerts_usecase.dart';
import 'domain/usecases/get_upsell_conversions_usecase.dart';
import 'domain/usecases/get_upsell_rules_usecase.dart';
import 'domain/usecases/save_combo_usecase.dart';
import 'domain/usecases/save_upsell_rule_usecase.dart';
import 'presentation/canteen_cubit.dart';

void initCanteenDI(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<CanteenRemoteDataSource>(
    () => CanteenRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<CanteenRepository>(
    () => CanteenRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCombosUseCase(sl()));
  sl.registerLazySingleton(() => SaveComboUseCase(sl()));
  sl.registerLazySingleton(() => DeleteComboUseCase(sl()));
  sl.registerLazySingleton(() => GetUpsellRulesUseCase(sl()));
  sl.registerLazySingleton(() => SaveUpsellRuleUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUpsellRuleUseCase(sl()));
  sl.registerLazySingleton(() => GetUpsellConversionsUseCase(sl()));
  sl.registerLazySingleton(() => GetLowStockAlertsUseCase(sl()));

  // Cubit
  sl.registerFactory(
    () => CanteenCubit(
      getCombosUseCase: sl(),
      saveComboUseCase: sl(),
      deleteComboUseCase: sl(),
      getUpsellRulesUseCase: sl(),
      saveUpsellRuleUseCase: sl(),
      deleteUpsellRuleUseCase: sl(),
      getUpsellConversionsUseCase: sl(),
      getLowStockAlertsUseCase: sl(),
    ),
  );
}
