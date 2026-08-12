import 'package:get_it/get_it.dart';
import 'presentation/dashboard_cubit.dart';

void initAnalyticsDI(GetIt sl) {
  // Cubits
  sl.registerFactory<DashboardCubit>(
    () => DashboardCubit(sl()),
  );
}
