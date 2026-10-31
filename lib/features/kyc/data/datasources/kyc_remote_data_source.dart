import 'dart:typed_data';

abstract class KycRemoteDataSource {
  Future<void> submitKyc({
    required String userId,
    required String loungeId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  });

  Future<List<Map<String, dynamic>>> getPendingReviews();

  Future<void> reviewKyc({
    required String requestId,
    required int revision,
    required bool approve,
    String? notes,
  });
}
