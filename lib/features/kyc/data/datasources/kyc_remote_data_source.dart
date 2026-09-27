import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const _bucket = 'kyc-documents';
  static const _signedUrlTtlSeconds = 15 * 60;

  final SupabaseClient _client;

  KycRemoteDataSourceImpl(this._client);

  String _safeExtension(String fileName) {
    final raw = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'pdf'};
    return allowed.contains(raw) ? raw : 'jpg';
  }

  Future<String?> _resolveDocumentReference(Object? value) async {
    final reference = value?.toString().trim() ?? '';
    if (reference.isEmpty || reference == 'null') return null;

    // Backward compatibility for legacy rows that stored long-lived signed URLs.
    if (reference.startsWith('https://') || reference.startsWith('http://')) {
      return reference;
    }

    return _client.storage
        .from(_bucket)
        .createSignedUrl(reference, _signedUrlTtlSeconds);
  }

  @override
  Future<void> submitKyc({
    required String userId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw StateError('KYC documents can only be submitted by their owner.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final idPath = '$userId/id_card_$now.${_safeExtension(idCardName)}';
    await _client.storage.from(_bucket).uploadBinary(idPath, idCardBytes);

    String? businessPath;
    if (businessDocBytes != null && businessDocName != null) {
      businessPath =
          '$userId/business_doc_$now.${_safeExtension(businessDocName)}';
      await _client.storage
          .from(_bucket)
          .uploadBinary(businessPath, businessDocBytes);
    }

    await _client.rpc(
      'submit_kyc_documents',
      params: {
        'p_id_document_url': idPath,
        'p_business_document_url': businessPath,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingReviews() async {
    final response = await _client.rpc('get_pending_kyc_reviews');
    if (response is! List) return const [];

    return Future.wait(
      response.map((raw) async {
        final map = Map<String, dynamic>.from(raw as Map);
        final idUrl = await _resolveDocumentReference(map['id_document_url']);
        final businessUrl = await _resolveDocumentReference(
          map['business_document_url'],
        );

        return <String, dynamic>{
          ...map,
          'id_document_url': idUrl ?? '',
          'business_document_url': businessUrl,
          'status': map['status']?.toString() ?? 'pending',
        };
      }),
    );
  }

  @override
  Future<void> reviewKyc({
    required String userId,
    required bool approve,
    String? notes,
  }) async {
    await _client.rpc(
      'review_kyc',
      params: {
        'p_user_id': userId,
        'p_approve': approve,
        'p_notes': notes,
      },
    );
  }
}
