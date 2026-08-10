import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/lounge_model.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';

abstract class OnboardingRemoteDataSource {
  Future<LoungeModel> setupLounge(Lounge lounge);
  Future<void> updateLoungeData(String id, Map<String, dynamic> data);
  Future<RoomModel> addRoom(RoomModel room);
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final SupabaseClient _supabase;

  OnboardingRemoteDataSourceImpl(this._supabase);

  @override
  Future<LoungeModel> setupLounge(Lounge lounge) async {
    final response = await _supabase.rpc('onboard_lounge', params: {
      'p_name': lounge.name,
      'p_description_ar': lounge.descriptionAr,
      'p_description_en': lounge.descriptionEn,
      'p_city': lounge.city,
      'p_location': lounge.location,
      'p_lat': lounge.lat,
      'p_lng': lounge.lng,
      'p_opens_at': lounge.opensAt,
      'p_closes_at': lounge.closesAt,
      'p_image_url': lounge.imageUrl,
      'p_images': lounge.images,
    });

    if (response == null) {
      throw Exception('Failed to onboard lounge');
    }

    return LoungeModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> updateLoungeData(String id, Map<String, dynamic> data) async {
    await _supabase.from('lounges').update(data).eq('id', id);
  }

  @override
  Future<RoomModel> addRoom(RoomModel room) async {
    final data = room.toJson();
    if (data['name'] == null || data['name'].toString().isEmpty) {
      data['name'] = room.nameEn.isEmpty ? 'Room' : room.nameEn;
    }
    final response = await _supabase.from('rooms').insert(data).select().single();
    return RoomModel.fromJson(response);
  }
}
