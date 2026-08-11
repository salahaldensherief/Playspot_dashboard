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
    
    final profile = await getCurrentUser();
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
  Future<UserModel?> getCurrentUser() async {
    try {
      if (supabaseClient.auth.currentSession == null) return null;
      
      final response = await supabaseClient.rpc('get_my_profile');
      if (response != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      // If RPC fails, try getting session user metadata as fallback if needed, 
      // but according to brief, rpc is the way.
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
        .single();
    
    return response['is_setup_completed'] == true;
  }
}
