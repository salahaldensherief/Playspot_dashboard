import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
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
    String? address,
    String? phone,
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
  Future<void> deleteLounge(String id);
  
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
      // 1. Direct query on lounges table (bypassing any legacy RPCs or invalid table relationships)
      final response = await client
          .from('lounges')
          .select()
          .neq('status', 'deleted')
          .order('created_at', ascending: false);

      final rawList = (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (rawList.isEmpty) return [];

      // 2. Batch fetch owner profiles directly from public.profiles table
      final ownerIds = rawList
          .map((json) => json['owner_id']?.toString())
          .where((id) => id != null && id.trim().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesMap = {};
      if (ownerIds.isNotEmpty) {
        try {
          final profilesResponse = await client
              .from('profiles')
              .select('id, full_name, email')
              .inFilter('id', ownerIds);

          for (final p in profilesResponse as List) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final pId = pMap['id']?.toString();
            if (pId != null) {
              profilesMap[pId] = pMap;
            }
          }
        } catch (e) {
          AppLogger.warning('Owner profiles batch fetch failed: $e');
        }
      }

      // 3. Map lounges and attach owner profile details
      final list = rawList.map((json) {
        final ownerId = json['owner_id']?.toString();
        if (ownerId != null && profilesMap.containsKey(ownerId)) {
          final p = profilesMap[ownerId]!;
          json['owner_name'] ??= p['full_name'];
          json['owner_email'] ??= p['email'];
        }
        return LoungeModel.fromJson(json);
      }).toList();

      return list;
    } catch (e) {
      AppLogger.error('Direct lounges query failed: $e');
      return [];
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
    String? address,
    String? phone,
  }) async {
    try {
      final response = await client.rpc('create_lounge_with_owner', params: {
        'p_owner_email': email,
        'p_owner_password': password,
        'p_owner_name': ownerName,
        'p_lounge_name': loungeName,
        'p_city': city,
        'p_address': address,
        'p_phone': phone,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      final response = await client.rpc('super_admin_create_lounge_with_owner', params: {
        'p_owner_email': email,
        'p_owner_password': password,
        'p_owner_name': ownerName,
        'p_lounge_name': loungeName,
        'p_city': city,
      });
      return Map<String, dynamic>.from(response);
    }
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
    cleanData.remove('opens_at');
    cleanData.remove('closes_at');
    cleanData.remove('description');
    cleanData.remove('lat');
    cleanData.remove('lng');
    cleanData.remove('latitude');
    cleanData.remove('longitude');

    // Sanitize time fields: if empty string ("") or null, omit key to prevent Postgres TIME type cast error
    for (final timeKey in ['opening_time', 'closing_time']) {
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
      AppLogger.info('updateLounge Succeeded for id: $id');
    } on PostgrestException catch (e) {
      AppLogger.error('updateLounge PostgrestException: ${e.message} (code: ${e.code}, details: ${e.details})');
      rethrow;
    } catch (e) {
      AppLogger.error('updateLounge Error: $e');
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
      AppLogger.info('updateLoungeDiscount Succeeded for id: $id');
    } on PostgrestException catch (e) {
      AppLogger.error('updateLoungeDiscount PostgrestException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (e) {
      AppLogger.error('updateLoungeDiscount Error: $e');
      rethrow;
    }
  }

  @override
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

  @override
  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await client.rpc('get_dashboard_overview');
      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      debugPrint('⚠️ [LOUNGE_DATA_SOURCE] getDashboardOverview RPC failed: $e');
    }
    return {
      'total_revenue': 0.0,
      'total_bookings': 0,
      'total_lounges': 0,
      'total_users': 0,
    };
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
      AppLogger.info('toggleLoungeOpenStatus Succeeded for loungeId: $loungeId, isOpen: $isOpen');
    } on PostgrestException catch (e) {
      AppLogger.error('toggleLoungeOpenStatus PostgrestException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (e) {
      AppLogger.error('toggleLoungeOpenStatus Error: $e');
      rethrow;
    }
  }

  @override
  Future<String> createLounge(LoungeModel lounge) async {
    final data = lounge.toJson();
    data.remove('id'); 
    data.remove('opens_at');
    data.remove('closes_at');
    data.remove('description');
    
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

  @override
  Future<void> deleteLounge(String id) async {
    try {
      await client.from('lounges').update({'status': 'deleted'}).eq('id', id);
      AppLogger.info('deleteLounge soft delete succeeded for id: $id');
    } catch (e) {
      AppLogger.warning('deleteLounge soft delete failed ($e), attempting hard delete...');
      await client.from('lounges').delete().eq('id', id);
      AppLogger.info('deleteLounge hard delete succeeded for id: $id');
    }
  }
}
