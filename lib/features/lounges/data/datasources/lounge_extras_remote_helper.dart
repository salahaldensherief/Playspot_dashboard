import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/extra_model.dart';

class LoungeExtrasRemoteHelper {
  final SupabaseClient client;

  LoungeExtrasRemoteHelper(this.client);

  Future<List<ExtraModel>> getExtras(String loungeId) async {
    final response = await client
        .from('extras')
        .select('*')
        .eq('lounge_id', loungeId)
        .eq('is_active', true);
    return (response as List).map((e) => ExtraModel.fromJson(e)).toList();
  }

  Future<void> addExtra(ExtraModel extra) async {
    await _saveExtra(extra);
  }

  Future<void> updateExtra(ExtraModel extra) async {
    await _saveExtra(extra);
  }

  Future<void> _saveExtra(ExtraModel extra) async {
    final response = await client.rpc(
      'save_lounge_extra',
      params: {'p_extra': extra.toJson()},
    );
    if (response is! Map || response['id']?.toString() != extra.id) {
      throw const FormatException('Invalid extra save response');
    }
  }

  Future<void> deleteExtra(String extraId) async {
    final response = await client.rpc(
      'archive_lounge_extra',
      params: {'p_extra_id': extraId},
    );
    if (response is! Map ||
        response['success'] != true ||
        response['extra_id']?.toString() != extraId) {
      throw const FormatException('Invalid extra archive response');
    }
  }

  Future<void> toggleExtraStock(String extraId, bool isOutOfStock) async {
    final response = await client.rpc(
      'set_lounge_extra_availability',
      params: {
        'p_extra_id': extraId,
        'p_is_available': !isOutOfStock,
      },
    );
    if (response is! Map ||
        response['success'] != true ||
        response['extra_id']?.toString() != extraId) {
      throw const FormatException('Invalid extra availability response');
    }
  }
}
