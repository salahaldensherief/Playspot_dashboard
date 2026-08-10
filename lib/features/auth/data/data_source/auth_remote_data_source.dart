import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });
  
  Future<void> logout();
  
  Future<UserModel?> getCurrentUser();
  
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
    
    final profile = await _getUserProfile(response.user!.id);
    return profile ?? UserModel(
      id: response.user!.id,
      email: response.user!.email!,
      name: response.user!.userMetadata?['full_name'] ?? 'Unknown',
      role: (response.user!.userMetadata?['role'] == 'super_admin') 
          ? UserRole.superAdmin 
          : UserRole.loungeAdmin,
    );
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;
    return await _getUserProfile(user.id);
  }

  @override
  Future<bool> checkSetupStatus(String loungeId) async {
    final response = await supabaseClient
        .from('lounges')
        .select('status')
        .eq('id', loungeId)
        .single();
    
    return response['status'] == 'active';
  }
  
  Future<UserModel?> _getUserProfile(String userId) async {
    try {
      final response = await supabaseClient.rpc('get_my_profile');
      if (response != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(response));
      }
      
      // Fallback to profiles table
      final profile = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (profile != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(profile));
      }
    } catch (e) {
      // Handle error or log
    }
    return null;
  }
}
