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
      return UserEntity(
        id: result['owner_user_id']?.toString() ?? '',
        role: UserRole.loungeAdmin,
        name: name,
        email: email,
        loungeId: result['lounge_id']?.toString(),
      );
    } else {
      throw Exception(result['message'] ?? 'Failed to create lounge admin');
    }
  }

  @override
  Future<List<UserEntity>> getAdmins() async {
    final response = await supabaseClient.from('profiles').select().order('full_name');
    return (response as List).map((json) {
      return UserEntity(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['full_name']?.toString() ?? '',
        role: json['role'] == 'super_admin' ? UserRole.superAdmin : UserRole.loungeAdmin,
        loungeId: json['lounge_id']?.toString(),
      );
    }).toList();
  }
}
