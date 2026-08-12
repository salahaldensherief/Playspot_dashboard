import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

abstract class KycRemoteDataSource {
  Future<void> submitKyc({
    required String userId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  });

  Future<List<Map<String, dynamic>>> getPendingReviews();

  Future<void> reviewKyc({
    required String userId,
    required bool approve,
    String? notes,
  });
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  final SupabaseClient _client;

  KycRemoteDataSourceImpl(this._client);

  @override
  Future<void> submitKyc({
    required String userId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  }) async {
    // 1. Upload ID Card to private bucket
    final idPath = '$userId/id_card_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('kyc-documents').uploadBinary(idPath, idCardBytes);
    final idUrl = _client.storage.from('kyc-documents').getPublicUrl(idPath);

    // 2. Upload Business Doc (Optional)
    String? bizUrl;
    if (businessDocBytes != null && businessDocName != null) {
      final bizPath = '$userId/business_doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('kyc-documents').uploadBinary(bizPath, businessDocBytes);
      bizUrl = _client.storage.from('kyc-documents').getPublicUrl(bizPath);
    }

    // 3. Call RPC to submit
    await _client.rpc('submit_kyc_documents', params: {
      'p_id_document_url': idUrl,
      'p_business_document_url': bizUrl,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingReviews() async {
    final response = await _client.rpc('get_pending_kyc_reviews');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> reviewKyc({
    required String userId,
    required bool approve,
    String? notes,
  }) async {
    await _client.rpc('review_kyc', params: {
      'p_user_id': userId,
      'p_approve': approve,
      'p_notes': notes,
    });
  }
}
