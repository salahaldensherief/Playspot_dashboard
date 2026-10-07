import 'package:play_spot_dashboard/core/services/lounge_owner_provisioner.dart';
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

class AdminManagementRemoteDataSourceImpl
    implements AdminManagementRemoteDataSource {
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
    final result = await LoungeOwnerProvisioner(supabaseClient).create(
      email: email,
      password: password,
      ownerName: name,
      loungeName: loungeName,
      city: city,
    );
    if (result['success'] == true) {
      final ownerUserId = result['owner_id'] as String;
      final loungeId = result['lounge_id'] as String;
      return UserEntity(
        id: ownerUserId,
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
          .select(
            'id, email, full_name, role, lounge_id, avatar_url, is_setup_completed, points, is_active, is_banned, banned_reason, city_id, cities:city_id(id, name_ar, name_en)',
          )
          .neq('role', 'inactive')
          .order('full_name');
      return (response as List)
          .where(
            (json) => json['is_active'] != false && json['role'] != 'inactive',
          )
          .map((json) {
            return UserModel.fromJson(Map<String, dynamic>.from(json));
          })
          .toList();
    } catch (_) {
      try {
        final fallbackResponse = await supabaseClient
            .from('profiles')
            .select('*, cities:city_id(id, name_ar, name_en)')
            .neq('role', 'inactive')
            .order('full_name');
        return (fallbackResponse as List)
            .where(
              (json) =>
                  json['is_active'] != false && json['role'] != 'inactive',
            )
            .map((json) {
              return UserModel.fromJson(Map<String, dynamic>.from(json));
            })
            .toList();
      } catch (fallbackError) {
        return [];
      }
    }
  }

  @override
  Future<void> deleteAdmin(String adminId) async {
    final cleanAdminId = adminId.trim();
    if (cleanAdminId.isEmpty) return;

    final response = await supabaseClient.functions.invoke(
      'deactivate-lounge-admin',
      body: {'target_user_id': cleanAdminId},
    );

    final data = response.data;
    if (data is! Map || data['success'] != true || data['auth_disabled'] != true) {
      final error = data is Map ? data['error']?.toString() : null;
      throw Exception(error ?? 'Failed to deactivate lounge admin');
    }
  }

  @override
  Future<void> updateAdmin(String adminId, Map<String, dynamic> data) async {
    final cleanData = UserModel.sanitizeProfilePayload(data);
    if (cleanData.isNotEmpty) {
      await supabaseClient.from('profiles').update(cleanData).eq('id', adminId);
    }
  }
}
