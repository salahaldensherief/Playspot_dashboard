import 'package:get_it/get_it.dart';
import 'presentation/cubit/marketing_cubit.dart';

void initMarketingDI(GetIt sl) {
  // Cubits
  sl.registerFactory<MarketingCubit>(
    () => MarketingCubit(),
  );
}
