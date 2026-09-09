import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });
  
  Future<void> logout();
  
  Future<UserModel?> getCurrentUser({String? userId});
  
  Future<bool> checkSetupStatus(String loungeId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw Exception('User not found');
    }
    
    final profile = await getCurrentUser(userId: response.user!.id);
    if (profile == null) {
       throw Exception('Profile not found');
    }
    return profile;
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser({String? userId}) async {
    try {
      final finalUserId = userId ?? supabaseClient.auth.currentUser?.id;
      if (finalUserId == null) {
        debugPrint('AuthRemoteDataSource: No authenticated user ID found');
        return null;
      }
      
      debugPrint('AuthRemoteDataSource: Fetching profile for ID: $finalUserId');

      // Check platform_super_admins table as single source of truth for Super Admin privilege
      bool isPlatformSuperAdmin = false;
      try {
        final superAdminCheck = await supabaseClient
            .from('platform_super_admins')
            .select('user_id')
            .eq('user_id', finalUserId)
            .maybeSingle();
        if (superAdminCheck != null) {
          isPlatformSuperAdmin = true;
          debugPrint('AuthRemoteDataSource: User $finalUserId confirmed as Platform Super Admin!');
        }
      } catch (e) {
        debugPrint('AuthRemoteDataSource: platform_super_admins query check error: $e');
      }

      // 1. Try RPC first
      final response = await supabaseClient.rpc('get_my_profile');
      if (response != null) {
        final map = Map<String, dynamic>.from(response as Map);
        if (isPlatformSuperAdmin) {
          map['role'] = 'super_admin';
        }
        debugPrint('AuthRemoteDataSource: Profile found via RPC (isPlatformSuperAdmin: $isPlatformSuperAdmin)');
        return UserModel.fromJson(map);
      }

      // 2. Fallback: Direct table select if RPC returns null
      debugPrint('AuthRemoteDataSource: RPC returned null, trying direct select...');
      final tableResponse = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', finalUserId)
          .maybeSingle();

      if (tableResponse != null) {
        final map = Map<String, dynamic>.from(tableResponse as Map);
        if (isPlatformSuperAdmin) {
          map['role'] = 'super_admin';
        }
        debugPrint('AuthRemoteDataSource: Profile found via direct select: $map (isPlatformSuperAdmin: $isPlatformSuperAdmin)');
        return UserModel.fromJson(map);
      }
      
      debugPrint('AuthRemoteDataSource: Profile record totally missing in profiles table');
    } catch (e) {
      debugPrint('AuthRemoteDataSource: Error in getCurrentUser: $e');
    }
    return null;
  }

  @override
  Future<bool> checkSetupStatus(String loungeId) async {
     // Brief says is_setup_completed is in profile, but kept this for compatibility
    final response = await supabaseClient
        .from('lounges')
        .select('is_setup_completed')
        .eq('id', loungeId)
        .maybeSingle();
    
    return response?['is_setup_completed'] == true;
  }
}
