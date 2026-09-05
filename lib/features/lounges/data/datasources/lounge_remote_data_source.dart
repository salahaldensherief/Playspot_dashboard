import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lounge_model.dart';
import '../models/extra_model.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';

abstract class LoungeRemoteDataSource {
  Future<List<LoungeModel>> getLounges();
  Future<LoungeModel?> getLoungeById(String id);
  Future<Map<String, dynamic>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
  });
  Future<void> updateLounge(String id, Map<String, dynamic> data);
  Future<void> updateLoungeDiscount(String id, {
    required bool hasDiscount,
    required int discountPercentage,
    String? titleAr,
    String? titleEn,
    DateTime? expiresAt,
  });
  Future<Map<String, dynamic>> getDashboardStats(String? loungeId);
  Future<Map<String, dynamic>> getDashboardOverview();
  Future<List<Map<String, dynamic>>> getRevenueOverTime(int daysBack);
  Future<List<Map<String, dynamic>>> getTopLoungesByRevenue(int limitCount);
  
  // Rooms & Activities
  Future<List<RoomModel>> getRooms(String loungeId);
  Future<List<Map<String, dynamic>>> getActivities(String roomId);
  
  // Extras
  Future<List<ExtraModel>> getExtras(String loungeId);
  Future<void> addExtra(ExtraModel extra);
  Future<void> updateExtra(ExtraModel extra);
  Future<void> deleteExtra(String extraId);
  Future<void> toggleExtraStock(String extraId, bool isOutOfStock);
  Future<void> toggleLoungeOpenStatus(String loungeId, bool isOpen);
  
  // Legacy methods - kept for compatibility if needed
  Future<String> createLounge(LoungeModel lounge);
  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  });
}

class LoungeRemoteDataSourceImpl implements LoungeRemoteDataSource {
  final SupabaseClient client;

  LoungeRemoteDataSourceImpl(this.client);

  @override
  Future<List<LoungeModel>> getLounges() async {
    try {
      final response = await client.rpc('get_all_lounges_with_owners');
      final list = (response as List).map((json) {
        return LoungeModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
      // Filter out deleted lounges in case the RPC doesn't
      return list.where((lounge) => lounge.status != 'deleted').toList();
    } catch (e) {
      final response = await client.from('lounges')
          .select()
          .neq('status', 'deleted');
      return (response as List).map((json) {
        return LoungeModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }
  }

  @override
  Future<LoungeModel?> getLoungeById(String id) async {
    final response = await client.from('lounges').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return LoungeModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<Map<String, dynamic>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
  }) async {
    final response = await client.rpc('super_admin_create_lounge_with_owner', params: {
      'p_owner_email': email,
      'p_owner_password': password,
      'p_owner_name': ownerName,
      'p_lounge_name': loungeName,
      'p_city': city,
    });
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> updateLounge(String id, Map<String, dynamic> data) async {
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('id');
    cleanData.remove('owner_name');
    cleanData.remove('owner_email');
    cleanData.remove('rating');
    cleanData.remove('distance');
    cleanData.remove('price_per_hour');
    cleanData.remove('available_rooms');
    cleanData.remove('total_reviews');

    // Sanitize time fields: if empty string ("") or null, omit key to prevent Postgres TIME type cast error
    for (final timeKey in ['opening_time', 'closing_time', 'opens_at', 'closes_at']) {
      if (cleanData.containsKey(timeKey)) {
        final val = cleanData[timeKey];
        if (val == null || (val is String && val.trim().isEmpty)) {
          cleanData.remove(timeKey);
        }
      }
    }

    cleanData.removeWhere((key, value) => value == null);

    try {
      await client.from('lounges').update(cleanData).eq('id', id);
      // ignore: avoid_print
      print('🟢 [Supabase] updateLounge Succeeded for id: $id');
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('🔴 [Supabase] updateLounge PostgrestException: ${e.message} (code: ${e.code}, details: ${e.details})');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('🔴 [Supabase] updateLounge Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLoungeDiscount(String id, {
    required bool hasDiscount,
    required int discountPercentage,
    String? titleAr,
    String? titleEn,
    DateTime? expiresAt,
  }) async {
    final updateData = <String, dynamic>{
      'has_discount': hasDiscount,
      'discount_percentage': discountPercentage,
      'discount_title_ar': titleAr,
      'discount_title_en': titleEn,
      'discount_expires_at': expiresAt?.toIso8601String(),
    };
    updateData.removeWhere((key, value) => value == null && key.contains('title'));

    try {
      await client.from('lounges').update(updateData).eq('id', id);
      // ignore: avoid_print
      print('🟢 [Supabase] updateLoungeDiscount Succeeded for id: $id');
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('🔴 [Supabase] updateLoungeDiscount PostgrestException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('🔴 [Supabase] updateLoungeDiscount Error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats(String? loungeId) async {
    final response = await client.rpc('get_dashboard_stats', params: {
      'p_lounge_id': loungeId,
    });
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> getDashboardOverview() async {
    final response = await client.rpc('get_dashboard_overview');
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getRevenueOverTime(int daysBack) async {
    final response = await client.rpc('get_revenue_over_time', params: {
      'days_back': daysBack,
    });
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTopLoungesByRevenue(int limitCount) async {
    final response = await client.rpc('get_top_lounges_by_revenue', params: {
      'limit_count': limitCount,
    });
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<List<RoomModel>> getRooms(String loungeId) async {
    final response = await client
        .from('rooms')
        .select('*')
        .eq('lounge_id', loungeId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => RoomModel.fromJson(json)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getActivities(String roomId) async {
    final response = await client
        .from('room_activities')
        .select('*, activity_types(*)')
        .eq('room_id', roomId);
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<List<ExtraModel>> getExtras(String loungeId) async {
    // Explicitly select columns to avoid PGRST204 error if schema cache is stale
    final response = await client
        .from('extras')
        .select('id, lounge_id, name, price, category, is_available')
        .eq('lounge_id', loungeId);
    return (response as List).map((e) => ExtraModel.fromJson(e)).toList();
  }

  @override
  Future<void> addExtra(ExtraModel extra) async {
    await client.from('extras').insert(extra.toJson());
  }

  @override
  Future<void> updateExtra(ExtraModel extra) async {
    await client.from('extras').update(extra.toJson()).eq('id', extra.id);
  }

  @override
  Future<void> deleteExtra(String extraId) async {
    await client.from('extras').delete().eq('id', extraId);
  }

  @override
  Future<void> toggleExtraStock(String extraId, bool isOutOfStock) async {
    await client.from('extras').update({'is_available': !isOutOfStock}).eq('id', extraId);
  }

  @override
  Future<void> toggleLoungeOpenStatus(String loungeId, bool isOpen) async {
    try {
      await client.from('lounges').update({'is_open': isOpen}).eq('id', loungeId);
      // ignore: avoid_print
      print('🟢 [Supabase] toggleLoungeOpenStatus Succeeded for loungeId: $loungeId, isOpen: $isOpen');
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('🔴 [Supabase] toggleLoungeOpenStatus PostgrestException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('🔴 [Supabase] toggleLoungeOpenStatus Error: $e');
      rethrow;
    }
  }

  @override
  Future<String> createLounge(LoungeModel lounge) async {
    final data = lounge.toJson();
    data.remove('id'); 
    
    final response = await client.from('lounges').insert(data).select('id').single();
    return response['id'].toString();
  }

  @override
  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  }) async {
    await client.rpc('create_lounge_admin', params: {
      'p_email': email,
      'p_password': password,
      'p_full_name': name,
      'p_lounge_id': loungeId,
    });
  }
}
