import 'package:flutter/foundation.dart';
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

    final regExp12 = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM|am|pm)$', caseSensitive: false);
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

    try {
      final response = await _supabase.rpc('onboard_lounge', params: {
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
      });

      if (response != null) {
        return LoungeModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint('OnboardingRemoteDataSource: onboard_lounge RPC error ($e), executing fallback update...');
      try {
        final updateData = <String, dynamic>{
          if (lounge.name.isNotEmpty) 'name': lounge.name,
          if (lounge.descriptionAr != null && lounge.descriptionAr!.isNotEmpty) 'description_ar': lounge.descriptionAr,
          if (lounge.descriptionEn != null && lounge.descriptionEn!.isNotEmpty) 'description_en': lounge.descriptionEn,
          if (lounge.city != null && lounge.city!.isNotEmpty) 'city': lounge.city,
          if (lounge.location != null && lounge.location!.isNotEmpty) 'location': lounge.location,
          if (cleanOpensAt.isNotEmpty) 'opening_time': cleanOpensAt,
          if (cleanClosesAt.isNotEmpty) 'closing_time': cleanClosesAt,
          if (lounge.imageUrl.isNotEmpty) 'image_url': lounge.imageUrl,
          if (lounge.images != null && lounge.images!.isNotEmpty) 'images': lounge.images,
        };

        if (lounge.lat != null && lounge.lng != null) {
          updateData['location_point'] = 'POINT(${lounge.lng} ${lounge.lat})';
        }

        await _supabase.from('lounges').update(updateData).eq('id', lounge.id);

        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId != null) {
          try {
            await _supabase.from('profiles').update({'is_setup_completed': true}).eq('id', currentUserId);
          } catch (_) {}
        }

        final loungeRes = await _supabase.from('lounges').select().eq('id', lounge.id).maybeSingle();
        if (loungeRes != null) {
          return LoungeModel.fromJson(loungeRes);
        }
      } catch (fallbackError) {
        debugPrint('OnboardingRemoteDataSource: Fallback update error: $fallbackError');
        throw Exception('Failed to setup lounge: $fallbackError');
      }
    }

    throw Exception('Failed to onboard lounge');
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
