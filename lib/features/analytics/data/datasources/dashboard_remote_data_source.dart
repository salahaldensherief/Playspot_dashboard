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
    if (loungeId == null || loungeId.isEmpty) {
      throw Exception('Lounge ID is required');
    }

    final response = await supabaseClient.rpc(
      'get_lounge_owner_dashboard_stats',
      params: {
        'p_lounge_id': loungeId,
      },
    );

    if (response == null) {
      throw Exception('No data received');
    }

    return LoungeStatsModel.fromJson(Map<String, dynamic>.from(response));
  }
}
