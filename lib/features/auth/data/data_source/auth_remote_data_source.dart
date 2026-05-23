import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../art_core/exceptions/app_exceptions.dart';
import '../models/admin_model.dart';

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

      return await _getAdminData(response.user!.id);
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
    return await _getAdminData(user.id);
  }

  Future<AdminModel> _getAdminData(String userId) async {
    final data = await _supabase
        .from('admins')
        .select('*, users(*)')
        .eq('user_id', userId)
        .single();

    return AdminModel.fromJson(data);
  }
}
