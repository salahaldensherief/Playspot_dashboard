import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';

abstract class RoomRemoteDataSource {
  Future<List<RoomModel>> getRooms(String loungeId);
  Stream<List<RoomModel>> watchRooms(String loungeId);
  Future<void> updateRoomStatus(String roomId, String status);
  Future<void> addRoom(RoomModel room);
  Future<void> updateRoom(RoomModel room);
  Future<void> deleteRoom(String roomId);
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final SupabaseClient _supabase;

  RoomRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<RoomModel>> getRooms(String loungeId) async {
    // Query rooms table directly with room_activities relation
    try {
      final response = await _supabase
          .from('rooms')
          .select('*, room_activities(*, activity_types(*))')
          .eq('lounge_id', loungeId)
          .neq('status', 'deleted')
          .order('created_at', ascending: true);
      return (response as List).map((json) => RoomModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ [ROOM_DATA_SOURCE] Joint query failed ($e), falling back to plain rooms query...');
      final response = await _supabase
          .from('rooms')
          .select('*')
          .eq('lounge_id', loungeId)
          .neq('status', 'deleted');
      return (response as List).map((json) => RoomModel.fromJson(json)).toList();
    }
  }

  @override
  Stream<List<RoomModel>> watchRooms(String loungeId) {
    return _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('lounge_id', loungeId)
        .asyncMap((event) async {
          return await getRooms(loungeId);
        });
  }

  @override
  Future<void> updateRoomStatus(String roomId, String status) async {
    await _supabase.from('rooms').update({'status': status}).eq('id', roomId);
  }

  @override
  Future<void> addRoom(RoomModel room) async {
    final data = room.toJson();
    if (data['name'] == null || data['name'].toString().isEmpty) {
      data['name'] = room.nameEn.isEmpty ? 'Room' : room.nameEn;
    }
    await _supabase.from('rooms').insert(data);
    await _syncRoomActivities(room.id, room.activityIds);
  }

  @override
  Future<void> updateRoom(RoomModel room) async {
    await _supabase.from('rooms').update(room.toJson()).eq('id', room.id);
    await _syncRoomActivities(room.id, room.activityIds);
  }

  Future<void> _syncRoomActivities(String roomId, List<String> activityIds) async {
    await _supabase.from('room_activities').delete().eq('room_id', roomId);
    
    if (activityIds.isNotEmpty) {
      final inserts = activityIds.map((id) => {
        'room_id': roomId,
        'activity_type_id': id,
      }).toList();
      await _supabase.from('room_activities').insert(inserts);
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      await _supabase.from('rooms').delete().eq('id', roomId);
    } catch (_) {
      await _supabase.from('rooms').update({'status': 'deleted'}).eq('id', roomId);
    }
  }
}
