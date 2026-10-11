import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';
import '../models/room_space_type_model.dart';

abstract class RoomRemoteDataSource {
  Future<List<RoomSpaceTypeModel>> getSpaceTypes();
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
  Future<List<RoomSpaceTypeModel>> getSpaceTypes() async {
    final rows = await _supabase
        .from('space_types')
        .select('id,name,label')
        .order('sort_order')
        .order('name');
    return rows.map((row) => RoomSpaceTypeModel.fromJson(row)).toList();
  }

  @override
  Future<List<RoomModel>> getRooms(String loungeId) async {
    // Query rooms table directly with room_activities relation
    try {
      final response = await _supabase
          .from('rooms')
          .select(
            '*, space_types(name,label), room_activities(*, activity_types(*))',
          )
          .eq('lounge_id', loungeId)
          .neq('status', 'deleted')
          .order('created_at', ascending: true);
      return (response as List)
          .map((json) => RoomModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint(
        '⚠️ [ROOM_DATA_SOURCE] Joint query failed ($e), falling back to plain rooms query...',
      );
      final response = await _supabase
          .from('rooms')
          .select('*')
          .eq('lounge_id', loungeId)
          .neq('status', 'deleted');
      return (response as List)
          .map((json) => RoomModel.fromJson(json))
          .toList();
    }
  }

  @override
  Stream<List<RoomModel>> watchRooms(String loungeId) async* {
    // 1. Initial REST fetch for instant & guaranteed loading
    try {
      final initialRooms = await getRooms(loungeId);
      yield initialRooms;
    } catch (e) {
      debugPrint('⚠️ [ROOM_DATA_SOURCE] Initial REST getRooms failed: $e');
    }

    // 2. Realtime Stream subscription with graceful exception fallback
    try {
      final stream = _supabase
          .from('rooms')
          .stream(primaryKey: ['id'])
          .eq('lounge_id', loungeId)
          .asyncMap((_) async => await getRooms(loungeId));

      await for (final rooms in stream) {
        yield rooms;
      }
    } catch (e) {
      debugPrint(
        '⚠️ [ROOM_DATA_SOURCE] Realtime stream failed ($e). Falling back to REST data.',
      );
      try {
        final fallbackRooms = await getRooms(loungeId);
        yield fallbackRooms;
      } catch (_) {}
    }
  }

  @override
  Future<void> updateRoomStatus(String roomId, String status) async {
    await _supabase.rpc(
      'set_room_operational_status',
      params: {'p_room_id': roomId, 'p_status': status},
    );
  }

  @override
  Future<void> addRoom(RoomModel room) => _saveRoom(room);

  @override
  Future<void> updateRoom(RoomModel room) => _saveRoom(room);

  Future<void> _saveRoom(RoomModel room) async {
    final response = await _supabase.rpc(
      'save_lounge_room_v2',
      params: {
        'p_room': room.toJson(),
        'p_activity_ids': room.activityIds,
      },
    );
    if (response is! Map ||
        response['success'] != true ||
        response['room_id']?.toString() != room.id) {
      throw const FormatException('Invalid room save response');
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    final response = await _supabase.rpc(
      'archive_lounge_room',
      params: {'p_room_id': roomId},
    );
    if (response is! Map ||
        response['success'] != true ||
        response['room_id']?.toString() != roomId ||
        response['status'] != 'deleted') {
      throw const FormatException('Invalid room archive response');
    }
  }
}
