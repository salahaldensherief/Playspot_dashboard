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
    final response = await _supabase
        .from('rooms')
        .select()
        .eq('lounge_id', loungeId)
        .order('name');
    return (response as List).map((json) => RoomModel.fromJson(json)).toList();
  }

  @override
  Stream<List<RoomModel>> watchRooms(String loungeId) {
    return _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('lounge_id', loungeId)
        .map((event) => event.map((json) => RoomModel.fromJson(json)).toList());
  }

  @override
  Future<void> updateRoomStatus(String roomId, String status) async {
    await _supabase.from('rooms').update({'status': status}).eq('id', roomId);
  }

  @override
  Future<void> addRoom(RoomModel room) async {
    final data = room.toJson();
    // Ensure name is never null for the database constraint
    if (data['name'] == null || data['name'].toString().isEmpty) {
      data['name'] = room.nameEn.isEmpty ? 'Room' : room.nameEn;
    }
    await _supabase.from('rooms').insert(data);
  }

  @override
  Future<void> updateRoom(RoomModel room) async {
    await _supabase.from('rooms').update(room.toJson()).eq('id', room.id);
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('rooms').update({'status': 'deleted'}).eq('id', roomId);
  }
}
