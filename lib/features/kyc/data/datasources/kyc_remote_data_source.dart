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
    try {
      final response = await _client.rpc('get_pending_kyc_reviews');
      if (response != null && response is List && response.isNotEmpty) {
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (_) {}

    // Direct table query on kyc_submissions joined with profiles via user_id
    try {
      final response = await _client
          .from('kyc_submissions')
          .select('*, profiles!inner(full_name, email, phone)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final list = (response as List).map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        final profile = map['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'user_id': map['user_id']?.toString() ?? '',
          'submission_id': map['id']?.toString() ?? '',
          'owner_name': profile['full_name']?.toString() ?? map['owner_name']?.toString() ?? 'Pending Owner',
          'owner_email': profile['email']?.toString() ?? map['owner_email']?.toString() ?? '',
          'owner_phone': profile['phone']?.toString() ?? map['phone']?.toString() ?? '',
          'lounge_name': map['lounge_name']?.toString() ?? 'Lounge',
          'id_document_url': map['id_document_url']?.toString() ?? '',
          'business_document_url': map['business_document_url']?.toString(),
          'status': map['status']?.toString() ?? 'pending',
          'notes': map['notes']?.toString(),
          'created_at': map['created_at']?.toString(),
        };
      }).toList();

      return list;
    } catch (_) {
      try {
        final response = await _client
            .from('kyc_submissions')
            .select('*')
            .eq('status', 'pending');

        final list = (response as List).map((json) {
          final map = Map<String, dynamic>.from(json as Map);
          return {
            'user_id': map['user_id']?.toString() ?? '',
            'submission_id': map['id']?.toString() ?? '',
            'owner_name': map['owner_name']?.toString() ?? 'Pending Owner',
            'owner_email': map['owner_email']?.toString() ?? '',
            'owner_phone': map['phone']?.toString() ?? '',
            'lounge_name': map['lounge_name']?.toString() ?? 'Lounge',
            'id_document_url': map['id_document_url']?.toString() ?? '',
            'business_document_url': map['business_document_url']?.toString(),
            'status': map['status']?.toString() ?? 'pending',
            'notes': map['notes']?.toString(),
            'created_at': map['created_at']?.toString(),
          };
        }).toList();

        return list;
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<void> reviewKyc({
    required String userId,
    required bool approve,
    String? notes,
  }) async {
    try {
      await _client.rpc('review_kyc', params: {
        'p_user_id': userId,
        'p_approve': approve,
        'p_notes': notes,
      });
      return;
    } catch (_) {}

    final statusStr = approve ? 'approved' : 'rejected';
    
    // Direct table update on kyc_submissions
    try {
      await _client
          .from('kyc_submissions')
          .update({
            'status': statusStr,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (_) {}

    // If approved, update user's profile role and lounge status for full platform access
    if (approve) {
      try {
        await _client
            .from('profiles')
            .update({
              'role': 'owner',
              'is_active': true,
              'is_setup_completed': true,
            })
            .eq('id', userId);
      } catch (_) {}

      try {
        await _client
            .from('lounges')
            .update({
              'status': 'active',
            })
            .eq('owner_id', userId);
      } catch (_) {}
    }
  }
}
