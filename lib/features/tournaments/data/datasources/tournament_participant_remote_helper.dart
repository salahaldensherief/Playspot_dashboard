import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/tournament_participant_model.dart';

class TournamentParticipantRemoteHelper {
  final SupabaseClient client;

  const TournamentParticipantRemoteHelper(this.client);

  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId) async {
    try {
      final response = await client
          .from('tournament_participants')
          .select()
          .eq('tournament_id', tournamentId)
          .order('created_at', ascending: false);

      final rawList = (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (rawList.isEmpty) return [];

      final userIds = rawList
          .map((json) => json['user_id']?.toString())
          .where((id) => id != null && id.trim().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await client
              .from('profiles')
              .select('id, full_name, phone, email, avatar_url')
              .inFilter('id', userIds);

          for (final p in profilesResponse as List) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final pId = pMap['id']?.toString();
            if (pId != null) {
              profilesMap[pId] = pMap;
            }
          }
        } catch (e) {
          AppLogger.error('Profiles batch fetch failed for participants', e);
        }
      }

      final list = rawList.map((json) {
        final uId = json['user_id']?.toString();
        if (uId != null && profilesMap.containsKey(uId)) {
          json['profiles'] = profilesMap[uId];
        }
        return TournamentParticipantModel.fromJson(json);
      }).toList();

      final resultWithSignedUrls = await Future.wait(list.map((p) async {
        if (p.receiptPath != null && p.receiptPath!.isNotEmpty) {
          try {
            final signedUrl = await client.storage
                .from('tournament-receipts')
                .createSignedUrl(p.receiptPath!, 3600);
            return p.copyWithSignedUrl(signedUrl);
          } catch (storageErr) {
            AppLogger.error('Failed to generate signed URL for receipt', storageErr);
          }
        }
        return p;
      }));

      return resultWithSignedUrls;
    } catch (e) {
      AppLogger.error('getParticipants error: $e', e);
      return [];
    }
  }

  Future<void> approvePayment(String participantId) async {
    try {
      await client.rpc('approve_tournament_payment', params: {'p_participant_id': participantId});
    } catch (e) {
      try {
        await client.rpc('approve_tournament_payment', params: {'participant_id': participantId});
      } catch (e2) {
        AppLogger.warning('approve_tournament_payment error', e2);
        rethrow;
      }
    }
  }

  Future<void> rejectPayment(String participantId, String reason) async {
    try {
      await client.rpc('reject_tournament_payment', params: {
        'p_participant_id': participantId,
        'p_reason': reason,
      });
    } catch (e) {
      try {
        await client.rpc('reject_tournament_payment', params: {
          'participant_id': participantId,
          'reason': reason,
        });
      } catch (e2) {
        AppLogger.warning('reject_tournament_payment error', e2);
        rethrow;
      }
    }
  }

  Future<void> recordCashPayment(String participantId) async {
    try {
      final participantRes = await client
          .from('tournament_participants')
          .select('tournament_id, registration_status, payment_status, tournaments(entry_fee)')
          .eq('id', participantId)
          .maybeSingle();

      double amount = 0.0;
      if (participantRes != null) {
        final tData = participantRes['tournaments'];
        if (tData is Map) {
          amount = (tData['entry_fee'] as num?)?.toDouble() ?? 0.0;
        }
      }

      await client.rpc('record_cash_tournament_payment', params: {
        'p_participant_id': participantId,
        'p_amount': amount,
        'p_reference_note': 'Cash payment recorded by admin',
      });
    } on PostgrestException catch (e) {
      if (e.code == 'P0001' && (e.message == 'payment_not_allowed' || e.message.contains('payment_not_allowed'))) {
        throw Exception('Payment is not allowed: Participant registration has expired or payment deadline has passed.');
      }
      rethrow;
    } catch (e) {
      AppLogger.error('recordCashPayment failed', e);
      rethrow;
    }
  }

  Future<void> checkInParticipant(String participantId) async {
    try {
      await client.rpc('check_in_tournament_participant', params: {'p_participant_id': participantId});
    } catch (e) {
      try {
        await client.rpc('check_in_tournament_participant', params: {'participant_id': participantId});
      } catch (e2) {
        AppLogger.warning('check_in_tournament_participant error', e2);
        rethrow;
      }
    }
  }

  Future<void> withdrawParticipant(String participantId) async {
    try {
      await client.rpc('withdraw_tournament_participant', params: {'p_participant_id': participantId});
    } catch (e) {
      try {
        await client.rpc('withdraw_tournament_participant', params: {'participant_id': participantId});
      } catch (e2) {
        AppLogger.warning('withdraw_tournament_participant error', e2);
        rethrow;
      }
    }
  }

  Future<void> promoteWaitlist(String tournamentId) async {
    try {
      await client.rpc('promote_tournament_waitlist', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      try {
        await client.rpc('promote_tournament_waitlist', params: {'tournament_id': tournamentId});
      } catch (e2) {
        AppLogger.warning('promote_tournament_waitlist error', e2);
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> submitTournamentPayment({
    required String tournamentId,
    required String participantId,
    required double amount,
    String? receiptUrl,
    String? userId,
  }) async {
    try {
      final response = await client.rpc('submit_tournament_payment', params: {
        'p_tournament_id': tournamentId,
        'p_participant_id': participantId,
        'p_amount': amount,
        'p_receipt_url': receiptUrl,
        'p_user_id': userId,
      });

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'success': true};
    } catch (e) {
      AppLogger.error('submitTournamentPayment failed', e);
      rethrow;
    }
  }
}
