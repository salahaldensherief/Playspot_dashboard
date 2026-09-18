import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class StorageService {
  Future<String> uploadLoungeImage(Uint8List fileBytes, String fileName, String loungeId);
  Future<List<String>> uploadLoungeImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId);
  Future<String> uploadRoomImage(Uint8List fileBytes, String fileName, String loungeId);
  Future<List<String>> uploadRoomImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId);
  Future<String> uploadTournamentBanner(Uint8List fileBytes, String fileName, String tournamentId);
  Future<String> uploadExtraImage(Uint8List fileBytes, String fileName, String loungeId);
}

class StorageServiceImpl implements StorageService {
  final SupabaseClient _supabase;

  StorageServiceImpl(this._supabase);

  @override
  Future<String> uploadLoungeImage(Uint8List fileBytes, String fileName, String loungeId) async {
    final fileId = const Uuid().v4();
    final extension = fileName.split('.').last;
    final path = '$loungeId/$fileId.$extension';
    
    try {
      await _supabase.storage.from('lounge-assets').uploadBinary(
        path, 
        fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return _supabase.storage.from('lounge-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [STORAGE_SERVICE] lounge-assets upload error: $e. Attempting fallback...');
      try {
        await _supabase.storage.from('promo-assets').uploadBinary(path, fileBytes);
        return _supabase.storage.from('promo-assets').getPublicUrl(path);
      } catch (e2) {
        throw Exception('عفواً، مجلد التخزين (Bucket) غير موجود في Supabase. يرجى إنشاء مجلد lounge-assets أو promo-assets وتحديده كـ Public.');
      }
    }
  }

  @override
  Future<List<String>> uploadLoungeImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId) async {
    final futures = List.generate(
      filesBytes.length,
      (i) => uploadLoungeImage(filesBytes[i], fileNames[i], loungeId),
    );
    return await Future.wait(futures);
  }

  @override
  Future<String> uploadRoomImage(Uint8List fileBytes, String fileName, String loungeId) async {
    final fileId = const Uuid().v4();
    final extension = fileName.split('.').last;
    final path = '$loungeId/$fileId.$extension';

    try {
      await _supabase.storage.from('room-assets').uploadBinary(path, fileBytes);
      return _supabase.storage.from('room-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [STORAGE_SERVICE] room-assets upload error: $e. Attempting fallback...');
      try {
        await _supabase.storage.from('lounge-assets').uploadBinary(path, fileBytes);
        return _supabase.storage.from('lounge-assets').getPublicUrl(path);
      } catch (e2) {
        throw Exception('عفواً، مجلد التخزين (Bucket) غير موجود في Supabase. يرجى إنشاء مجلد room-assets أو lounge-assets.');
      }
    }
  }

  @override
  Future<List<String>> uploadRoomImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId) async {
    final futures = List.generate(
      filesBytes.length,
      (i) => uploadRoomImage(filesBytes[i], fileNames[i], loungeId),
    );
    return await Future.wait(futures);
  }

  @override
  Future<String> uploadTournamentBanner(Uint8List fileBytes, String fileName, String tournamentId) async {
    final extension = fileName.contains('.') ? fileName.split('.').last : 'webp';
    final path = '$tournamentId/banner.$extension';

    try {
      await _supabase.storage.from('tournament-assets').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      return _supabase.storage.from('tournament-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [STORAGE_SERVICE] tournament-assets upload error: $e. Attempting fallback...');
      try {
        await _supabase.storage.from('promo-assets').uploadBinary(path, fileBytes);
        return _supabase.storage.from('promo-assets').getPublicUrl(path);
      } catch (e2) {
        throw Exception('عفواً، مجلد التخزين (Bucket) غير موجود في Supabase. يرجى إنشاء مجلد tournament-assets أو promo-assets.');
      }
    }
  }

  @override
  Future<String> uploadExtraImage(Uint8List fileBytes, String fileName, String loungeId) async {
    final fileId = const Uuid().v4();
    final extension = fileName.contains('.') ? fileName.split('.').last : 'png';
    final path = 'extras/$loungeId/$fileId.$extension';

    try {
      await _supabase.storage.from('lounge-assets').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return _supabase.storage.from('lounge-assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('⚠️ [STORAGE_SERVICE] uploadExtraImage error: $e. Attempting promo-assets fallback...');
      try {
        await _supabase.storage.from('promo-assets').uploadBinary(path, fileBytes);
        return _supabase.storage.from('promo-assets').getPublicUrl(path);
      } catch (e2) {
        throw Exception('فشل رفع صورة المنتج. يرجى التأكد من وجود مجلد lounge-assets كـ Public في Supabase Storage.');
      }
    }
  }
}
