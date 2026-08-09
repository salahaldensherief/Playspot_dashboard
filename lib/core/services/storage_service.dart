import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class StorageService {
  Future<String> uploadLoungeImage(Uint8List fileBytes, String fileName);
  Future<String> uploadRoomImage(Uint8List fileBytes, String fileName, String loungeId);
}

class StorageServiceImpl implements StorageService {
  final SupabaseClient _supabase;

  StorageServiceImpl(this._supabase);

  @override
  Future<String> uploadLoungeImage(Uint8List fileBytes, String fileName) async {
    final path = 'lounges/${const Uuid().v4()}_$fileName';
    await _supabase.storage.from('lounge-assets').uploadBinary(path, fileBytes);
    return _supabase.storage.from('lounge-assets').getPublicUrl(path);
  }

  @override
  Future<String> uploadRoomImage(Uint8List fileBytes, String fileName, String loungeId) async {
    final path = '$loungeId/rooms/${const Uuid().v4()}_$fileName';
    await _supabase.storage.from('room-assets').uploadBinary(path, fileBytes);
    return _supabase.storage.from('room-assets').getPublicUrl(path);
  }
}
