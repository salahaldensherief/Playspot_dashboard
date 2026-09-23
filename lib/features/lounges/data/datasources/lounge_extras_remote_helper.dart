import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/extra_model.dart';

class LoungeExtrasRemoteHelper {
  final SupabaseClient client;

  LoungeExtrasRemoteHelper(this.client);

  Future<List<ExtraModel>> getExtras(String loungeId) async {
    final response = await client
        .from('extras')
        .select('*')
        .eq('lounge_id', loungeId);
    return (response as List).map((e) => ExtraModel.fromJson(e)).toList();
  }

  Future<void> addExtra(ExtraModel extra) async {
    await client.from('extras').insert(extra.toJson());
  }

  Future<void> updateExtra(ExtraModel extra) async {
    await client.from('extras').update(extra.toJson()).eq('id', extra.id);
  }

  Future<void> deleteExtra(String extraId) async {
    await client.from('extras').delete().eq('id', extraId);
  }

  Future<void> toggleExtraStock(String extraId, bool isOutOfStock) async {
    await client
        .from('extras')
        .update({'is_available': !isOutOfStock})
        .eq('id', extraId);
  }
}
