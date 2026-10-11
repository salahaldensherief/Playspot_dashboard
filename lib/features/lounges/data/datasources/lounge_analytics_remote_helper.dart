import 'package:supabase_flutter/supabase_flutter.dart';

class LoungeAnalyticsRemoteHelper {
  final SupabaseClient client;

  LoungeAnalyticsRemoteHelper(this.client);

  Future<Map<String, dynamic>> getDashboardStats(String? loungeId) async {
    if (loungeId == null || loungeId.isEmpty) return getDashboardOverview();
    final response = await client.rpc(
      'get_lounge_owner_dashboard_stats',
      params: {'p_lounge_id': loungeId},
    );
    return _dashboardMap(response);
  }

  Future<Map<String, dynamic>> getDashboardOverview() async {
    final response = await client.rpc('get_dashboard_overview');
    return _dashboardMap(response);
  }

  Map<String, dynamic> _dashboardMap(Object? response) {
    if (response is! Map) {
      throw const FormatException('invalid_dashboard_response');
    }
    final map = Map<String, dynamic>.from(response);
    final rawOccupancy = map['occupancy_rate'];
    if (rawOccupancy is num) {
      final value = rawOccupancy.toDouble();
      map['occupancy_rate'] = value > 1
          ? (value / 100).clamp(0.0, 1.0)
          : value.clamp(0.0, 1.0);
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getRevenueOverTime(String period) async {
    final response = await client.rpc(
      'get_revenue_over_time',
      params: {'p_period': period},
    );
    return (response as List)
        .map((e) => {...Map<String, dynamic>.from(e), 'day': e['period']})
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTopLoungesByRevenue(
    int limitCount,
  ) async {
    final response = await client.rpc(
      'get_top_lounges_by_revenue',
      params: {'limit_count': limitCount},
    );
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
