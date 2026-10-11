import 'package:get_it/get_it.dart';
import 'data/datasources/pricing_remote_datasource.dart';
import 'data/repositories/pricing_repository_impl.dart';
import 'domain/repositories/pricing_repository.dart';
import 'domain/usecases/check_pricing_rule_conflicts_usecase.dart';
import 'domain/usecases/delete_pricing_rule_usecase.dart';
import 'domain/usecases/get_pricing_rules_usecase.dart';
import 'domain/usecases/quote_booking_price_usecase.dart';
import 'domain/usecases/save_pricing_rule_usecase.dart';
import 'presentation/pricing_cubit.dart';

void initPricingDI(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<PricingRemoteDataSource>(
    () => PricingRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<PricingRepository>(
    () => PricingRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPricingRulesUseCase(sl()));
  sl.registerLazySingleton(() => SavePricingRuleUseCase(sl()));
  sl.registerLazySingleton(() => DeletePricingRuleUseCase(sl()));
  sl.registerLazySingleton(() => CheckPricingRuleConflictsUseCase(sl()));
  sl.registerLazySingleton(() => QuoteBookingPriceUseCase(sl()));

  // Cubit
  sl.registerFactory(
    () => PricingCubit(
      getPricingRulesUseCase: sl(),
      savePricingRuleUseCase: sl(),
      deletePricingRuleUseCase: sl(),
      checkPricingRuleConflictsUseCase: sl(),
      quoteBookingPriceUseCase: sl(),
    ),
  );
}
