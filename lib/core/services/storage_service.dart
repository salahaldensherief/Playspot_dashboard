import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'bucket_upload_strategy.dart';

abstract class StorageService {
  Future<String> uploadLoungeImage(Uint8List fileBytes, String fileName, String loungeId);
  Future<List<String>> uploadLoungeImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId);
  Future<String> uploadRoomImage(Uint8List fileBytes, String fileName, String loungeId);
  Future<List<String>> uploadRoomImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId);
  Future<String> uploadTournamentBanner(Uint8List fileBytes, String fileName, String tournamentId);
  Future<String> uploadExtraImage(Uint8List fileBytes, String fileName, String loungeId);
}

class StorageServiceImpl implements StorageService {
  final BucketUploadStrategy _strategy;

  StorageServiceImpl(SupabaseClient supabase) : _strategy = BucketUploadStrategy(supabase);

  @override
  Future<String> uploadLoungeImage(Uint8List fileBytes, String fileName, String loungeId) async {
    final fileId = const Uuid().v4();
    final extension = fileName.split('.').last;
    final path = '$loungeId/$fileId.$extension';

    return _strategy.uploadWithFallback(
      buckets: ['lounge-assets', 'promo-assets'],
      path: path,
      fileBytes: fileBytes,
      userErrorMessage: 'فشل رفع صورة اللاونج. يرجى التأكد من الاتصال بالإنترنت وصحة الصورة ثم إعادة المحاولة.',
    );
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

    return _strategy.uploadWithFallback(
      buckets: ['room-assets', 'lounge-assets'],
      path: path,
      fileBytes: fileBytes,
      userErrorMessage: 'فشل رفع صورة الغرفة. يرجى التأكد من الاتصال بالإنترنت وصحة الصورة ثم إعادة المحاولة.',
    );
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

    return _strategy.uploadWithFallback(
      buckets: ['tournament-assets', 'promo-assets'],
      path: path,
      fileBytes: fileBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      userErrorMessage: 'فشل رفع صورة إعلان البطولة. يرجى التأكد من الاتصال بالإنترنت ثم إعادة المحاولة.',
    );
  }

  @override
  Future<String> uploadExtraImage(Uint8List fileBytes, String fileName, String loungeId) async {
    final fileId = const Uuid().v4();
    final extension = fileName.contains('.') ? fileName.split('.').last : 'png';
    final path = 'extras/$loungeId/$fileId.$extension';

    return _strategy.uploadWithFallback(
      buckets: ['lounge-assets', 'promo-assets'],
      path: path,
      fileBytes: fileBytes,
      userErrorMessage: 'فشل رفع صورة المنتج. يرجى التأكد من الاتصال بالإنترنت ثم إعادة المحاولة.',
    );
  }
}
