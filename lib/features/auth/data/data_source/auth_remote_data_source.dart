import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/art_core/exceptions/app_exceptions.dart';
import 'package:play_spot_dashboard/features/auth/data/models/admin_model.dart';

abstract class AuthRemoteDataSource {
  Future<AdminModel> login(String email, String password);
  Future<void> logout();
  Future<AdminModel?> getCurrentAdmin();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl(this._supabase);

  @override
  Future<AdminModel> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AppException('Login failed: User is null');
      }

      final admin = await getCurrentAdmin();
      if (admin == null) {
        throw AppException('No admin profile found for this account.');
      }
      return admin;
    } on AuthException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<AdminModel?> getCurrentAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Try to use the new RPC 'get_my_profile'
      final response = await _supabase.rpc('get_my_profile').timeout(
        const Duration(seconds: 5),
      );
      
      if (response != null) {
        final data = Map<String, dynamic>.from(response);
        data['users'] = {
          'email': user.email,
          'name': data['full_name'] ?? 'Admin',
          'avatar_url': data['avatar_url'],
        };
        return AdminModel.fromJson(data);
      }
    } catch (e) {
      // 2. Fallback to direct table query if RPC fails/doesn't exist
      try {
        final data = await _supabase
            .from('admins')
            .select('*')
            .eq('user_id', user.id)
            .maybeSingle();

        if (data != null) {
          data['users'] = {
            'email': user.email,
            'name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'Admin',
            'avatar_url': user.userMetadata?['avatar_url'],
          };
          return AdminModel.fromJson(data);
        }
      } catch (tableError) {
        // Log error or handle it
      }
    }
    return null;
  }
}
