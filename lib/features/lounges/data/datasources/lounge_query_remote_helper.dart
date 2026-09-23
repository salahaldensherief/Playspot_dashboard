import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../models/lounge_model.dart';

class LoungeQueryRemoteHelper {
  final SupabaseClient client;

  LoungeQueryRemoteHelper(this.client);

  Future<List<LoungeModel>> getLounges() async {
    List<Map<String, dynamic>> rawList = [];

    try {
      final response = await client
          .from('lounges')
          .select()
          .neq('status', 'deleted')
          .order('created_at', ascending: false);

      rawList = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((json) => json['status'] != 'deleted' && json['is_active'] != false)
          .toList();
    } catch (e, stackTrace) {
      AppLogger.warning('Direct lounges select query failed ($e), attempting RPC fallbacks...', e, stackTrace);

      try {
        final fallbackResponse = await client.rpc('get_all_lounges');
        if (fallbackResponse is List && fallbackResponse.isNotEmpty) {
          rawList = fallbackResponse
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((json) => json['status'] != 'deleted' && json['is_active'] != false)
              .toList();
        }
      } catch (_) {}

      if (rawList.isEmpty) {
        try {
          final fallbackResponse = await client.rpc('get_top_lounges_by_revenue', params: {'limit_count': 100});
          if (fallbackResponse is List && fallbackResponse.isNotEmpty) {
            rawList = fallbackResponse
                .map((e) => Map<String, dynamic>.from(e as Map))
                .where((json) => json['status'] != 'deleted' && json['is_active'] != false)
                .toList();
          }
        } catch (_) {}
      }
    }

    if (rawList.isEmpty) {
      return [];
    }

    final ownerIds = rawList
        .map((j) => j['owner_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    Map<String, Map<String, String>> ownerProfileMap = {};
    if (ownerIds.isNotEmpty) {
      try {
        final profilesRes = await client
            .from('profiles')
            .select('id, full_name, email')
            .filter('id', 'in', ownerIds);

        for (final p in profilesRes as List) {
          final pMap = Map<String, dynamic>.from(p as Map);
          final pid = pMap['id']?.toString() ?? '';
          if (pid.isNotEmpty) {
            ownerProfileMap[pid] = {
              'name': pMap['full_name']?.toString() ?? '',
              'email': pMap['email']?.toString() ?? '',
            };
          }
        }
      } catch (profileErr) {
        AppLogger.warning('Failed to batch fetch owner profiles for lounges: $profileErr');
      }
    }

    return rawList.map((json) {
      final ownerId = json['owner_id']?.toString();
      if (ownerId != null && ownerProfileMap.containsKey(ownerId)) {
        final profile = ownerProfileMap[ownerId]!;
        json['owner_name'] = profile['name'];
        json['owner_email'] = profile['email'];
      }
      return LoungeModel.fromJson(json);
    }).toList();
  }

  Future<LoungeModel?> getLoungeById(String id) async {
    try {
      final rpcResponse = await client.rpc('get_lounge_details', params: {
        'p_lounge_id': id,
      });

      if (rpcResponse != null) {
        Map<String, dynamic> json = {};
        if (rpcResponse is List && rpcResponse.isNotEmpty) {
          json = Map<String, dynamic>.from(rpcResponse.first as Map);
        } else if (rpcResponse is Map) {
          json = Map<String, dynamic>.from(rpcResponse);
        }

        if (json.isNotEmpty) {
          if (json.containsKey('lounge') && json['lounge'] is Map) {
            json = Map<String, dynamic>.from(json['lounge'] as Map);
          }
          if (json.containsKey('id')) {
            return LoungeModel.fromJson(json);
          }
        }
      }
    } catch (e) {
      AppLogger.warning('get_lounge_details RPC failed ($e), falling back to direct table query');
    }

    final response = await client.from('lounges').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return LoungeModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Map<String, dynamic>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
    String? address,
    String? phone,
  }) async {
    Map<String, dynamic> resMap;
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
      resMap = Map<String, dynamic>.from(response);
    } catch (e) {
      if (e is PostgrestException && (e.code == '42501' || e.message.contains('permission denied'))) {
        throw Exception('عفواً، لا تملك الصلاحية الكافية لإنشاء الصالة على الخادم.');
      }
      try {
        final response = await client.rpc('super_admin_create_lounge_with_owner', params: {
          'p_owner_email': email,
          'p_owner_password': password,
          'p_owner_name': ownerName,
          'p_lounge_name': loungeName,
          'p_city': city,
        });
        resMap = Map<String, dynamic>.from(response);
      } on PostgrestException catch (pe) {
        if (pe.code == '42501' || pe.message.contains('permission denied')) {
          throw Exception('عفواً، تم رفض الإذن بإنشاء الصالة من قبل الخادم.');
        }
        throw Exception(pe.message);
      } catch (e2) {
        throw Exception(e2.toString());
      }
    }

    final ownerUserId = resMap['owner_user_id']?.toString() ?? resMap['owner_id']?.toString();

    if (ownerUserId != null && ownerUserId.isNotEmpty) {
      try {
        await client.from('profiles').update({
          'role': 'owner',
          'is_setup_completed': false,
        }).eq('id', ownerUserId);
      } catch (_) {}
    }

    return resMap;
  }

  Future<void> deleteLounge(String id) async {
    try {
      await client.from('lounges').update({'status': 'deleted'}).eq('id', id);
      AppLogger.info('deleteLounge soft delete succeeded for id: $id');
      return;
    } catch (e) {
      AppLogger.warning('deleteLounge soft delete direct update failed ($e), attempting RPC delete...');
    }

    try {
      await client.rpc('delete_lounge_admin', params: {'p_lounge_id': id});
      AppLogger.info('deleteLounge delete_lounge_admin RPC succeeded for id: $id');
      return;
    } catch (_) {}

    try {
      await client.rpc('super_admin_delete_lounge', params: {'p_lounge_id': id});
      AppLogger.info('deleteLounge super_admin_delete_lounge RPC succeeded for id: $id');
      return;
    } catch (e) {
      AppLogger.error('deleteLounge soft delete failed: $e');
      throw Exception('فشل تعليق الصالة: لا تملك الصلاحيات الكافية لتعديل حالة الصالة.');
    }
  }
}
