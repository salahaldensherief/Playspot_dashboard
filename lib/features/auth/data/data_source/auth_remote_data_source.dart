import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/art_core/exceptions/app_exceptions.dart';
import 'package:play_spot_dashboard/features/auth/data/models/admin_model.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_entity.dart';

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
         // Final Fallback: use Auth User data if DB view is not ready
         return AdminModel(
           id: response.user!.id,
           userId: response.user!.id,
           role: AdminRole.loungeAdmin,
           name: response.user!.userMetadata?['full_name'] ?? 'Lounge Admin',
           email: response.user!.email ?? '',
         );
      }
      return admin;
    } on AuthException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      debugPrint('Critical Login Error: $e');
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

    // 1. Primary Strategy: Use the profiles view (as per backend report)
    try {
      final data = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return AdminModel.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      debugPrint('Profile view query failed: $e');
    }

    // 2. Secondary Strategy: Use RPC if view fails
    try {
      final response = await _supabase.rpc('get_my_profile');
      if (response != null) {
        return AdminModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint('RPC get_my_profile failed: $e');
    }

    return null;
  }
}
