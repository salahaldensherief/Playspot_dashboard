import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/lounge_model.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

abstract class OnboardingRemoteDataSource {
  Future<LoungeModel> setupLounge(Lounge lounge);
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final SupabaseClient _supabase;

  OnboardingRemoteDataSourceImpl(this._supabase);

  @override
  Future<LoungeModel> setupLounge(Lounge lounge) async {
    // Using the new 'onboard_lounge' RPC from backend report
    final response = await _supabase.rpc('onboard_lounge', params: {
      'p_name': lounge.name,
      'p_description_ar': lounge.descriptionAr,
      'p_description_en': lounge.descriptionEn,
      'p_city': lounge.city,
      'p_location': lounge.location,
      'p_opens_at': lounge.opensAt,
      'p_closes_at': lounge.closesAt,
      'p_image_url': lounge.imageUrl,
    });

    if (response == null) {
      throw Exception('Failed to onboard lounge');
    }

    return LoungeModel.fromJson(Map<String, dynamic>.from(response));
  }
}
