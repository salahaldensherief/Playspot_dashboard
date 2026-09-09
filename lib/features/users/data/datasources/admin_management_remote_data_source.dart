import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/data/models/user_model.dart';

abstract class AdminManagementRemoteDataSource {
  Future<UserEntity> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeName,
    String? city,
  });
  
  Future<List<UserEntity>> getAdmins();
  Future<void> deleteAdmin(String adminId);
  Future<void> updateAdmin(String adminId, Map<String, dynamic> data);
}

class AdminManagementRemoteDataSourceImpl implements AdminManagementRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdminManagementRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserEntity> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeName,
    String? city,
  }) async {
    final result = await supabaseClient.rpc('super_admin_create_lounge_with_owner', params: {
      'p_owner_email': email,
      'p_owner_password': password,
      'p_owner_name': name,
      'p_lounge_name': loungeName,
      'p_city': city,
    });

    if (result['success'] == true) {
      final ownerUserId = result['owner_user_id']?.toString();
      final loungeId = result['lounge_id']?.toString();

      if (ownerUserId != null && ownerUserId.isNotEmpty) {
        try {
          await supabaseClient
              .from('profiles')
              .update({'is_setup_completed': false})
              .eq('id', ownerUserId);
        } catch (_) {}
      }

      return UserEntity(
        id: ownerUserId ?? '',
        role: UserRole.owner,
        name: name,
        email: email,
        loungeId: loungeId,
        isSetupCompleted: false,
      );
    } else {
      throw Exception(result['message'] ?? 'Failed to create lounge admin');
    }
  }

  @override
  Future<List<UserEntity>> getAdmins() async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select('id, email, full_name, role, lounge_id, avatar_url, is_setup_completed, points_balance, reward_points, referral_count, referrals_count, is_active')
          .neq('role', 'inactive')
          .order('full_name');
      return (response as List)
          .where((json) => json['is_active'] != false && json['role'] != 'inactive')
          .map((json) {
        return UserModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (_) {
      try {
        final fallbackResponse = await supabaseClient
            .from('profiles')
            .select()
            .neq('role', 'inactive')
            .order('full_name');
        return (fallbackResponse as List)
            .where((json) => json['is_active'] != false && json['role'] != 'inactive')
            .map((json) {
          return UserModel.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      } catch (fallbackError) {
        return [];
      }
    }
  }

  @override
  Future<void> deleteAdmin(String adminId) async {
    final cleanAdminId = adminId.trim();
    if (cleanAdminId.isEmpty) return;

    // 1. Unassign lounge ownership if this admin is a lounge owner
    try {
      await supabaseClient
          .from('lounges')
          .update({'owner_id': null})
          .eq('owner_id', cleanAdminId);
    } catch (e) {
      // ignore
    }

    // 2. Remove staff association if any
    try {
      await supabaseClient
          .from('lounge_staff')
          .delete()
          .eq('user_id', cleanAdminId);
    } catch (_) {}

    // 3. Attempt hard delete from profiles
    try {
      await supabaseClient.from('profiles').delete().eq('id', cleanAdminId);
    } on PostgrestException catch (_) {
      // 4. Soft delete fallback if hard delete is restricted by DB foreign keys or RLS
      await supabaseClient.from('profiles').update({
        'is_active': false,
        'role': 'inactive',
      }).eq('id', cleanAdminId);
    } catch (_) {
      await supabaseClient.from('profiles').update({
        'is_active': false,
        'role': 'inactive',
      }).eq('id', cleanAdminId);
    }
  }

  @override
  Future<void> updateAdmin(String adminId, Map<String, dynamic> data) async {
    await supabaseClient.from('profiles').update(data).eq('id', adminId);
  }
}
