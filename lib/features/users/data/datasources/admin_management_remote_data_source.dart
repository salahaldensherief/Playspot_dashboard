import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/admin_entity.dart';

abstract class AdminManagementRemoteDataSource {
  Future<AdminEntity> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
  });
}

class AdminManagementRemoteDataSourceImpl implements AdminManagementRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdminManagementRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<AdminEntity> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    // In a real scenario, this might call a Supabase Edge Function or Auth API
    // Since we are mocking for now as requested or to keep it simple:
    await Future.delayed(const Duration(seconds: 2));
    
    return AdminEntity(
      id: 'new-admin-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: AdminRole.loungeAdmin,
      name: name,
      email: email,
    );
  }
}
