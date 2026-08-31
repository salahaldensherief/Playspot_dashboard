import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lounge_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<LoungeStatsModel> fetchLoungeStats(String? loungeId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient supabaseClient;

  DashboardRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<LoungeStatsModel> fetchLoungeStats(String? loungeId) async {
    final response = await supabaseClient.rpc(
      'get_lounge_owner_dashboard_stats',
      params: {
        if (loungeId != null) 'p_lounge_id': loungeId,
      },
    );

    if (response == null) {
      throw Exception('Failed to fetch dashboard stats');
    }

    return LoungeStatsModel.fromJson(Map<String, dynamic>.from(response));
  }
}
