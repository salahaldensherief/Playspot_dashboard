import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'kyc_remote_data_source.dart';

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

    if (reference.contains('://') || reference.contains('..')) {
      throw const FormatException('invalid_kyc_document_reference');
    }

    return _client.storage
        .from(_bucket)
        .createSignedUrl(reference, _signedUrlTtlSeconds);
  }

  @override
  Future<void> submitKyc({
    required String userId,
    required String loungeId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw StateError('KYC documents can only be submitted by their owner.');
    }

    if (loungeId.isEmpty || idCardBytes.isEmpty) {
      throw const FormatException('invalid_kyc_submission');
    }
    final idPath =
        '$userId/$loungeId/id_${sha256.convert(idCardBytes)}.${_safeExtension(idCardName)}';
    await _uploadImmutable(idPath, idCardBytes);

    String? businessPath;
    if (businessDocBytes != null && businessDocName != null) {
      businessPath =
          '$userId/$loungeId/business_${sha256.convert(businessDocBytes)}.${_safeExtension(businessDocName)}';
      await _uploadImmutable(businessPath, businessDocBytes);
    }

    final response = await _client.rpc(
      'submit_lounge_review',
      params: {
        'p_lounge_id': loungeId,
        'p_id_document_path': idPath,
        'p_business_document_path': businessPath,
      },
    );
    if (response is! Map ||
        response['success'] != true ||
        response['request_id'] is! String ||
        (response['request_id'] as String).trim().isEmpty ||
        response['revision'] is! int ||
        (response['revision'] as int) < 1 ||
        response['status'] != 'pending') {
      throw const FormatException('invalid_kyc_submission_response');
    }
  }

  Future<void> _uploadImmutable(String path, Uint8List bytes) async {
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: false),
          );
    } on StorageException catch (error) {
      // Only an existing immutable content-addressed object is a retry.
      if (error.error != 'Duplicate' && error.statusCode != '409') rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingReviews() async {
    final response = await _client.rpc('get_lounge_review_requests');
    if (response is! List) {
      throw const FormatException('invalid_kyc_review_response');
    }

    return Future.wait(
      response.map((raw) async {
        final map = Map<String, dynamic>.from(raw as Map);
        if (map['id'] is! String ||
            map['revision'] is! int ||
            (map['revision'] as int) < 1 ||
            map['lounge_id'] is! String) {
          throw const FormatException('invalid_kyc_review_response');
        }
        final idUrl = await _resolveDocumentReference(map['id_document_path']);
        final businessUrl = await _resolveDocumentReference(
          map['business_document_path'],
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
    required String requestId,
    required int revision,
    required bool approve,
    String? notes,
  }) async {
    final response = await _client.rpc(
      'review_lounge_request',
      params: {
        'p_request_id': requestId,
        'p_revision': revision,
        'p_approve': approve,
        'p_notes': notes,
      },
    );
    if (response is! Map ||
        response['success'] != true ||
        response['request_id'] != requestId) {
      throw const FormatException('invalid_kyc_decision_response');
    }
  }
}
