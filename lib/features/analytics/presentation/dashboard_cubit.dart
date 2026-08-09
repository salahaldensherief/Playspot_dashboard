import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final SupabaseClient _supabase;
  DashboardCubit(this._supabase) : super(DashboardState.init());

  Future<void> loadDashboardData({String? loungeId}) async {
    if (isClosed) return;
    emit(state.copyWith(status: FeatureStatus.loading));
    
    try {
      final response = await _supabase.rpc('get_dashboard_stats', params: {
        if (loungeId != null) 'p_lounge_id': loungeId,
      });

      if (response != null) {
        // Map the real data from RPC to state
        final data = Map<String, dynamic>.from(response);
        emit(state.copyWith(
          status: FeatureStatus.success,
          // Assuming your state has these fields, otherwise we extend it
          // totalRevenue: data['total_revenue'], etc.
        ));
      }
    } catch (e) {
      emit(state.copyWith(status: FeatureStatus.failure, errorMessage: e.toString()));
    }
  }
}
