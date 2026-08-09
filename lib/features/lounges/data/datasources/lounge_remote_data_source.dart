import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lounge_model.dart';

abstract class LoungeRemoteDataSource {
  Future<List<LoungeModel>> getLounges();
  Future<String> createLounge(LoungeModel lounge);
  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  });
}

class LoungeRemoteDataSourceImpl implements LoungeRemoteDataSource {
  final SupabaseClient client;

  LoungeRemoteDataSourceImpl(this.client);

  @override
  Future<List<LoungeModel>> getLounges() async {
    try {
      // The most basic select to pinpoint the source of "invalid uuid: lounges"
      final response = await client.from('lounges').select();
      
      return (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        // Ensure we don't process owner info if the join isn't active
        return LoungeModel.fromJson(data);
      }).toList();
    } catch (e) {
      // If this still fails with "invalid uuid: lounges", then 'lounges' is likely a reserved word 
      // or there is a schema conflict in the project.
      rethrow;
    }
  }

  @override
  Future<String> createLounge(LoungeModel lounge) async {
    final data = lounge.toJson();
    data.remove('id'); 
    
    final response = await client.from('lounges').insert(data).select('id').single();
    return response['id'].toString();
  }

  @override
  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  }) async {
    await client.rpc('create_lounge_admin', params: {
      'p_email': email,
      'p_password': password,
      'p_full_name': name,
      'p_lounge_id': loungeId,
    });
  }
}
