import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});

  Future<void> logout();

  Future<UserModel?> getCurrentUser({String? userId});

  Future<bool> checkSetupStatus(String loungeId);

  Future<UserModel> updateUserLocation({
    required double latitude,
    required double longitude,
  });
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
    final authenticatedId = supabaseClient.auth.currentUser?.id;
    try {
      if (authenticatedId == null ||
          (userId != null && userId != authenticatedId)) {
        return null;
      }
      final finalUserId = authenticatedId;

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
          debugPrint(
            'AuthRemoteDataSource: User $finalUserId confirmed as Platform Super Admin!',
          );
        }
      } catch (e) {
        debugPrint(
          'AuthRemoteDataSource: platform_super_admins query check error: $e',
        );
      }

      // 1. Try RPC first
      final response = await supabaseClient.rpc('get_my_profile');
      if (supabaseClient.auth.currentUser?.id != authenticatedId) return null;
      if (response != null) {
        final map = Map<String, dynamic>.from(response as Map);
        if (map['id'] != authenticatedId) return null;
        if (isPlatformSuperAdmin &&
            map['is_active'] == true &&
            map['is_banned'] == false) {
          map['role'] = 'super_admin';
        }
        debugPrint(
          'AuthRemoteDataSource: Profile found via RPC (isPlatformSuperAdmin: $isPlatformSuperAdmin)',
        );
        return UserModel.fromJson(map);
      }

      // 2. Fallback: Direct table select if RPC returns null
      debugPrint(
        'AuthRemoteDataSource: RPC returned null, trying direct select...',
      );
      final tableResponse = await supabaseClient
          .from('profiles')
          .select('*, cities:city_id(id, name_ar, name_en)')
          .eq('id', finalUserId)
          .maybeSingle();

      if (tableResponse != null) {
        final map = Map<String, dynamic>.from(tableResponse as Map);
        if (supabaseClient.auth.currentUser?.id != authenticatedId ||
            map['id'] != authenticatedId) {
          return null;
        }
        if (isPlatformSuperAdmin &&
            map['is_active'] == true &&
            map['is_banned'] == false) {
          map['role'] = 'super_admin';
        }
        debugPrint('AuthRemoteDataSource: Profile found via direct select');
        return UserModel.fromJson(map);
      }

      debugPrint(
        'AuthRemoteDataSource: Profile record totally missing in profiles table',
      );
    } catch (_) {
      if (supabaseClient.auth.currentUser?.id != authenticatedId) return null;
      rethrow;
    }
    if (supabaseClient.auth.currentUser?.id != authenticatedId) return null;
    throw StateError('Authenticated profile is missing');
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

  @override
  Future<UserModel> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid coordinates');
    }
    final session = supabaseClient.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      throw const AuthException('Authentication required (401)');
    }
    void requireSameActor() {
      if (supabaseClient.auth.currentSession?.user.id != session.user.id) {
        throw const AuthException('Authentication changed (401)');
      }
    }

    bool locationSaved = false;
    try {
      // The configured client supplies both the API key and current access token.
      final response = await supabaseClient.functions.invoke(
        'update-user-location',
        body: {'latitude': latitude, 'longitude': longitude},
      );
      requireSameActor();
      if (response.status != 200 ||
          response.data is! Map ||
          response.data['success'] != true) {
        throw const FormatException(
          'Location service did not confirm the update',
        );
      }
      locationSaved = true;
    } on FunctionException catch (error) {
      requireSameActor();
      // Never replace validation or authorization failures with a direct write.
      if (error.status < 500) rethrow;
      debugPrint('Location city lookup unavailable: ${error.status}');
    }

    if (!locationSaved) {
      requireSameActor();
      // Retain coordinates during a city-service outage without inventing a city.
      // RLS still authorizes this update; an empty/denied update is an error.
      await supabaseClient
          .from('profiles')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', session.user.id)
          .select('id')
          .single();
      requireSameActor();
    }
    final updated = await getCurrentUser(userId: session.user.id);
    requireSameActor();
    if (updated == null || updated.id != session.user.id) {
      throw const FormatException('Could not refresh the updated user profile');
    }
    return updated;
  }
}
