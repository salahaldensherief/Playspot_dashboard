import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';

class LoungeAnalyticsRemoteHelper {
  final SupabaseClient client;

  LoungeAnalyticsRemoteHelper(this.client);

  Future<Map<String, dynamic>> getDashboardStats(String? loungeId) async {
    if (loungeId != null && loungeId.isNotEmpty) {
      try {
        final response = await client.rpc('get_lounge_owner_dashboard_stats', params: {
          'p_lounge_id': loungeId,
        });
        if (response != null && response is Map) {
          return Map<String, dynamic>.from(response);
        }
      } catch (_) {}
    }

    try {
      final response = await client.rpc('get_dashboard_overview');
      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}

    return {
      'total_revenue': 0.0,
      'total_bookings': 0,
      'active_rooms': 0,
      'occupancy_rate': 0.0,
    };
  }

  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await client.rpc('get_dashboard_overview');
      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      AppLogger.warning('getDashboardOverview RPC failed: $e');
    }
    return {
      'total_revenue': 0.0,
      'total_bookings': 0,
      'total_lounges': 0,
      'total_users': 0,
    };
  }

  Future<List<Map<String, dynamic>>> getRevenueOverTime(int daysBack) async {
    final response = await client.rpc('get_revenue_over_time', params: {
      'days_back': daysBack,
    });
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getTopLoungesByRevenue(int limitCount) async {
    final response = await client.rpc('get_top_lounges_by_revenue', params: {
      'limit_count': limitCount,
    });
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
