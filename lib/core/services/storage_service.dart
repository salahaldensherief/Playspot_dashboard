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
    // Changed path: removed "lounges/" prefix which caused UUID casting error in RLS
    final fileId = const Uuid().v4();
    final extension = fileName.split('.').last;
    final path = '$fileId.$extension';
    
    await _supabase.storage.from('lounge-assets').uploadBinary(
      path, 
      fileBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
    
    return _supabase.storage.from('lounge-assets').getPublicUrl(path);
  }

  @override
  Future<String> uploadRoomImage(Uint8List fileBytes, String fileName, String loungeId) async {
    final fileId = const Uuid().v4();
    final extension = fileName.split('.').last;
    final path = '$loungeId/$fileId.$extension';

    await _supabase.storage.from('room-assets').uploadBinary(path, fileBytes);
    return _supabase.storage.from('room-assets').getPublicUrl(path);
  }
}
