import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lounge_model.dart';

abstract class LoungeRemoteDataSource {
  Future<List<LoungeModel>> getLounges();
  Future<void> createLounge(LoungeModel lounge);
}

class LoungeRemoteDataSourceImpl implements LoungeRemoteDataSource {
  final SupabaseClient client;

  LoungeRemoteDataSourceImpl(this.client);

  @override
  Future<List<LoungeModel>> getLounges() async {
    final response = await client.from('lounges').select();
    return (response as List).map((json) => LoungeModel.fromJson(json)).toList();
  }

  @override
  Future<void> createLounge(LoungeModel lounge) async {
    // Note: location_point is handled by a database trigger or a RPC
    // We send lat/lng and let the trigger: 
    // NEW.location_point := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
    await client.from('lounges').insert(lounge.toJson());
  }
}
