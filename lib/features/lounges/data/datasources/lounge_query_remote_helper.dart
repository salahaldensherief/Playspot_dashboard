import 'package:play_spot_dashboard/core/services/lounge_owner_provisioner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../models/lounge_model.dart';

class LoungeQueryRemoteHelper {
  final SupabaseClient client;

  LoungeQueryRemoteHelper(this.client);

  Future<List<LoungeModel>> getLounges() async {
    // Management includes pending and suspended venues. Discovery and revenue
    // rankings have different scopes and cannot substitute for a failed read.
    final response = await client
        .from('lounges')
        .select()
        .neq('status', 'deleted')
        .order('created_at', ascending: false);
    final rawList = response
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => row['status'] != 'deleted')
        .toList();

    if (rawList.isEmpty) {
      return [];
    }

    // A count failure must remain an error rather than presenting a false zero.
    // Include rooms under maintenance, but not soft-deleted rooms.
    final loungeIds = rawList.map((row) => row['id'].toString()).toList();
    final roomCounts = {for (final id in loungeIds) id: 0};
    const pageSize = 1000;
    for (var offset = 0; ; offset += pageSize) {
      final rooms = await client
          .from('rooms')
          .select('id,lounge_id,status')
          .inFilter('lounge_id', loungeIds)
          .order('id')
          .range(offset, offset + pageSize - 1);
      for (final room in rooms) {
        final id = room['lounge_id']?.toString();
        if (id != null &&
            room['status'] != 'deleted' &&
            roomCounts.containsKey(id)) {
          roomCounts[id] = (roomCounts[id] ?? 0) + 1;
        }
      }
      if (rooms.length < pageSize) break;
    }
    for (final row in rawList) {
      row['available_rooms'] = roomCounts[row['id'].toString()];
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
            .inFilter('id', ownerIds.whereType<String>().toList());

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
        AppLogger.warning(
          'Failed to batch fetch owner profiles for lounges: $profileErr',
        );
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
      final rpcResponse = await client.rpc(
        'get_lounge_details',
        params: {'p_lounge_id': id},
      );

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
      AppLogger.warning(
        'get_lounge_details RPC failed ($e), falling back to direct table query',
      );
    }

    final response = await client
        .from('lounges')
        .select()
        .eq('id', id)
        .maybeSingle();
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
    String? ownerPhone,
  }) async {
    return LoungeOwnerProvisioner(client).create(
      email: email,
      password: password,
      ownerName: ownerName,
      loungeName: loungeName,
      city: city,
      address: address,
      phone: phone,
      ownerPhone: ownerPhone,
    );
  }

  Future<void> deleteLounge(String id) async {
    try {
      await client.from('lounges').update({'status': 'deleted'}).eq('id', id);
      AppLogger.info('deleteLounge soft delete succeeded for id: $id');
      return;
    } catch (e) {
      AppLogger.warning(
        'deleteLounge soft delete direct update failed ($e), attempting RPC delete...',
      );
    }

    try {
      await client.rpc('delete_lounge_admin', params: {'p_lounge_id': id});
      AppLogger.info(
        'deleteLounge delete_lounge_admin RPC succeeded for id: $id',
      );
      return;
    } catch (_) {}

    try {
      await client.rpc(
        'super_admin_delete_lounge',
        params: {'p_lounge_id': id},
      );
      AppLogger.info(
        'deleteLounge super_admin_delete_lounge RPC succeeded for id: $id',
      );
      return;
    } catch (e) {
      AppLogger.error('deleteLounge soft delete failed: $e');
      rethrow;
    }
  }

  Future<List<LoungeModel>> getOwnerBranches(String ownerId) async {
    try {
      final response = await client.rpc(
        'get_owner_branches',
        params: {'p_owner_id': ownerId},
      );

      if (response is List) {
        return response
            .map(
              (e) => LoungeModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'get_owner_branches RPC failed ($e), falling back to select query...',
        e,
        stackTrace,
      );
    }

    try {
      final response = await client
          .from('lounges')
          .select()
          .eq('owner_id', ownerId)
          .neq('status', 'deleted')
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => LoungeModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      AppLogger.error('Fallback query for owner branches failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addLoungeBranch(
    Map<String, dynamic> branchData,
  ) async {
    final response = await client.rpc(
      'add_lounge_branch',
      params: {'p_branch_data': branchData},
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'id': response?.toString() ?? ''};
  }

  Future<Map<String, dynamic>> getMultiBranchOverview({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await client.rpc(
      'get_multi_branch_overview',
      params: {
        'p_owner_id': ownerId,
        'p_start_date': startDate.toUtc().toIso8601String(),
        'p_end_date': endDate.toUtc().toIso8601String(),
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }
}
