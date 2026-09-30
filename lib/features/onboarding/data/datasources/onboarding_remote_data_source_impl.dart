import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../lounges/data/models/lounge_model.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../../rooms/data/models/room_model.dart';
import 'onboarding_remote_data_source.dart';

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final SupabaseClient _supabase;

  OnboardingRemoteDataSourceImpl(this._supabase);

  String _sanitizeTimeFormat(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '00:00:00';
    final input = timeStr.trim();

    final is24h = RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$');
    if (is24h.hasMatch(input)) {
      final parts = input.split(':');
      final h = int.parse(parts[0]).toString().padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      final s = parts.length > 2 ? parts[2].padLeft(2, '0') : '00';
      return '$h:$m:$s';
    }

    final regExp12 = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM|am|pm)$',
      caseSensitive: false,
    );
    final match = regExp12.firstMatch(input);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = match.group(2) ?? '00';
      final period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour < 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      final hStr = hour.toString().padLeft(2, '0');
      return '$hStr:$minute:00';
    }

    return input;
  }

  @override
  Future<LoungeModel> setupLounge(Lounge lounge) async {
    final cleanOpensAt = _sanitizeTimeFormat(lounge.opensAt);
    final cleanClosesAt = _sanitizeTimeFormat(lounge.closesAt);

    final response = await _supabase.rpc(
      'onboard_lounge',
      params: {
        'p_name': lounge.name,
        'p_description_ar': lounge.descriptionAr,
        'p_description_en': lounge.descriptionEn,
        'p_city': lounge.city,
        'p_location': lounge.location,
        'p_lat': lounge.lat,
        'p_lng': lounge.lng,
        'p_opens_at': cleanOpensAt,
        'p_closes_at': cleanClosesAt,
        'p_image_url': lounge.imageUrl,
        'p_images': lounge.images,
      },
    );
    if (response is! Map ||
        response['success'] != true ||
        response['lounge_id'] is! String) {
      throw const FormatException('invalid_onboarding_response');
    }
    return _readLounge(response['lounge_id'] as String);
  }

  Future<LoungeModel> _readLounge(String loungeId) async {
    final row = await _supabase
        .from('lounges')
        .select()
        .eq('id', loungeId)
        .single();
    if (row['id'] != loungeId) {
      throw const FormatException('invalid_onboarding_response');
    }
    return LoungeModel.fromJson(row);
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
    final response = await _supabase
        .from('rooms')
        .insert(data)
        .select()
        .single();
    return RoomModel.fromJson(response);
  }

  @override
  Future<LoungeModel> batchCompleteOnboarding({
    required String loungeId,
    required Map<String, dynamic> loungeData,
    required List<Map<String, dynamic>> rooms,
    required List<Map<String, dynamic>> extras,
  }) async {
    await _supabase.rpc(
      'batch_complete_onboarding',
      params: {
        'p_lounge_id': loungeId,
        'p_lounge_data': loungeData,
        'p_rooms': rooms,
        'p_extras': extras,
      },
    );
    return _readLounge(loungeId);
  }
}
