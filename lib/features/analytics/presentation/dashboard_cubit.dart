import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final SupabaseClient _supabase;
  DashboardCubit(this._supabase) : super(DashboardState.init());

  void loadDashboardData({String? loungeId}) async {
    if (isClosed) return;
    emit(state.copyWith(status: FeatureStatus.loading));
    
    try {
      // Using the new 'get_dashboard_stats' RPC from backend report
      final response = await _supabase.rpc('get_dashboard_stats', params: {
        if (loungeId != null) 'p_lounge_id': loungeId,
      });

      if (response != null) {
        // Here you would map the response to your state
        // For now emitting success
        emit(state.copyWith(status: FeatureStatus.success));
      }
    } catch (e) {
      emit(state.copyWith(status: FeatureStatus.failure, errorMessage: e.toString()));
    }
  }
}
