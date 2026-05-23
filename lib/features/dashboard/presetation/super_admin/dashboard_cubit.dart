import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardState.init());

  void loadDashboardData() async {
    if (isClosed) return;
    emit(state.copyWith(status: FeatureStatus.loading));
    // Simulate data fetch
    await Future.delayed(const Duration(seconds: 1));
    if (isClosed) return;
    emit(state.copyWith(status: FeatureStatus.success));
  }
}
