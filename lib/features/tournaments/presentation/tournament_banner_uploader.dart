import 'dart:typed_data';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';

class TournamentBannerUploader {
  final StorageService storageService;

  const TournamentBannerUploader(this.storageService);

  Future<String?> upload({
    required Uint8List? bytes,
    required String? name,
    required String tournamentId,
  }) async {
    if (bytes == null || name == null) return null;
    try {
      return await storageService.uploadTournamentBanner(bytes, name, tournamentId);
    } catch (e) {
      AppLogger.error('Banner upload failed: $e');
      rethrow;
    }
  }
}
