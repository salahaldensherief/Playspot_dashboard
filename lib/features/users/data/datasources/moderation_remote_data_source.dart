import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_ban_request_model.dart';

abstract class ModerationRemoteDataSource {
  Future<void> createBanRequest({
    required String loungeId,
    required String userId,
    String? bookingId,
    required String reason,
    String? evidenceNotes,
  });

  Future<List<UserBanRequestModel>> getLoungeBanRequests(String loungeId);

  Future<List<UserBanRequestModel>> getPendingBanRequests();

  Future<void> approveLoungeBanRequest(String requestId, {String? adminNotes});

  Future<void> approveGlobalBanRequest(String requestId, {String? adminNotes});

  Future<void> rejectBanRequest(String requestId, {String? adminNotes});

  Future<void> suspendLounge(String loungeId, {required String reason});
}

class ModerationRemoteDataSourceImpl implements ModerationRemoteDataSource {
  final SupabaseClient client;

  ModerationRemoteDataSourceImpl(this.client);

  @override
  Future<void> createBanRequest({
    required String loungeId,
    required String userId,
    String? bookingId,
    required String reason,
    String? evidenceNotes,
  }) async {
    try {
      final payload = {
        'lounge_id': loungeId,
        'user_id': userId,
        if (bookingId != null && bookingId.isNotEmpty) 'booking_id': bookingId,
        'reason': reason,
        if (evidenceNotes != null && evidenceNotes.isNotEmpty) 'evidence_notes': evidenceNotes,
        'status': 'pending',
      };

      await client.from('user_ban_requests').insert(payload);
      debugPrint('🟢 [MODERATION] Ban request created successfully');
    } catch (e) {
      debugPrint('❌ [MODERATION] createBanRequest Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserBanRequestModel>> getLoungeBanRequests(String loungeId) async {
    try {
      final response = await client
          .from('user_ban_requests')
          .select('*, profiles(full_name, phone, email)')
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => UserBanRequestModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      debugPrint('❌ [MODERATION] getLoungeBanRequests Error: $e');
      return [];
    }
  }

  @override
  Future<List<UserBanRequestModel>> getPendingBanRequests() async {
    try {
      final response = await client
          .from('user_ban_requests')
          .select('*, profiles(full_name, phone, email), lounges(name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List).map((json) => UserBanRequestModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      debugPrint('❌ [MODERATION] getPendingBanRequests Error: $e');
      return [];
    }
  }

  @override
  Future<void> approveLoungeBanRequest(String requestId, {String? adminNotes}) async {
    try {
      await client.rpc('approve_lounge_ban_request', params: {
        'request_id': requestId,
        'admin_notes': adminNotes ?? '',
      });
      debugPrint('🟢 [MODERATION] Approved lounge ban request $requestId');
    } catch (e) {
      debugPrint('❌ [MODERATION] approveLoungeBanRequest Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> approveGlobalBanRequest(String requestId, {String? adminNotes}) async {
    try {
      await client.rpc('approve_global_ban_request', params: {
        'request_id': requestId,
        'admin_notes': adminNotes ?? '',
      });
      debugPrint('🟢 [MODERATION] Approved global ban request $requestId');
    } catch (e) {
      debugPrint('❌ [MODERATION] approveGlobalBanRequest Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectBanRequest(String requestId, {String? adminNotes}) async {
    try {
      await client.rpc('reject_ban_request', params: {
        'request_id': requestId,
        'admin_notes': adminNotes ?? '',
      });
      debugPrint('🟢 [MODERATION] Rejected ban request $requestId');
    } catch (e) {
      debugPrint('❌ [MODERATION] rejectBanRequest Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> suspendLounge(String loungeId, {required String reason}) async {
    try {
      await client.rpc('suspend_lounge', params: {
        'lounge_id': loungeId,
        'reason': reason,
      });
      debugPrint('🟢 [MODERATION] Suspended lounge $loungeId');
    } catch (e) {
      debugPrint('❌ [MODERATION] suspendLounge Error: $e');
      rethrow;
    }
  }
}
